module transpiler

const (
	strings_to_builtin = ['compare', 'contains', 'contains_any', 'count', 'fields', 'index',
		'index_any', 'index_byte', 'last_index', 'last_index_byte', 'repeat', 'split', 'title',
		'to_lower', 'to_upper', 'trim', 'trim_left', 'trim_prefix', 'trim_right', 'trim_space',
		'trim_suffix']
	name_equivalence   = {
		'string': 'str'
		'rune':   'runes'
	}
	string_builder_diffs = ['cap', 'grow', 'len', 'reset', 'string', 'write']
)

fn (mut v VAST) stmt_to_string(stmt Statement) string {
	v.handle_stmt(stmt, true)
	return v.out.cut_last(v.out.len)
}

// `fmt.println(a)` -> `println(a)`
fn (mut v VAST) style_print(stmt CallStmt, right string) Statement {
	if right == 'println' || right == 'print' {
		mut call_stmt := CallStmt{
			namespaces: right
		}

		if stmt.args.len > 1 {
			mut out := "'"
			for i, arg in stmt.args {
				out += '\${${v.stmt_to_string(arg)}}'
				out += if i != stmt.args.len - 1 { ' ' } else { "'" }
			}
			call_stmt.args = [BasicValueStmt{out}]
		} else {
			call_stmt.args = stmt.args
		}

		return call_stmt
	} else {
		v.unused_import['fmt'] = true
	}
	return stmt
}

// see `tests/string_builder_bytes` & `tests/string_builder_strings`
fn (v VAST) style_string_builder(stmt CallStmt, left string, right string) Statement {
	match right {
		'grow' {
			return CallStmt{
				namespaces: '${left}.ensure_cap'
				args: stmt.args
			}
		}
		'cap', 'len' {
			return BasicValueStmt{stmt.namespaces}
		}
		'reset' {
			return UnsafeStmt{[
				CallStmt{
					namespaces: '${left}.free'
				},
				VariableStmt{
					names: ['${left}.offset', '${left}.len']
					middle: '='
					values: [BasicValueStmt{'0'}, BasicValueStmt{'0'}]
				},
			]}
		}
		'string' {
			return CallStmt{
				namespaces: '${left}.str'
			}
		}
		'write' {
			return OptionalStmt{stmt}
		}
		else {}
	}
	return stmt
}

// `fn_name(arg)` -> `arg.fn_name`
fn (mut v VAST) style_fn_to_decl(stmt CallStmt, left string) Statement {
	right := if left in transpiler.name_equivalence {
		transpiler.name_equivalence[left]
	} else {
		left
	}
	return BasicValueStmt{'${v.stmt_to_string(stmt.args[0])}.$right'}
}

// `make(map[string]int)` -> `map[string]int{}`
fn (mut v VAST) style_make(stmt CallStmt) Statement {
	return BasicValueStmt{'${v.stmt_to_string(stmt.args[0])}{}'}
}

// `delete(map, key)` -> `map.delete(key)`
fn (mut v VAST) style_delete(stmt CallStmt) Statement {
	return CallStmt{
		namespaces: '${v.stmt_to_string(stmt.args[0])}.delete'
		args: [stmt.args[1]]
	}
}

fn (mut v VAST) style_strings_module(stmt CallStmt, right string) Statement {
	if transpiler.strings_to_builtin.contains(right) {
		if stmt.args.len == 1 {
			return CallStmt{
				namespaces: '${v.stmt_to_string(stmt.args[0])}.$right'
			}
		}
		return CallStmt{
			namespaces: '${v.stmt_to_string(stmt.args[0])}.$right'
			args: [stmt.args[1]]
		}
	} else if right == 'new_builder' {
		v.string_builder_vars << v.current_var_name
	} else {
		v.unused_import['strings'] = true
	}
	return stmt
}

fn (mut v VAST) style_stmt(stmt Statement) Statement {
	mut out_stmt := stmt

	if stmt is CallStmt {
		ns := stmt.namespaces.split('.')
		first_ns := ns.first()
		last_ns := ns.last()
		all_but_last_ns := stmt.namespaces#[..-last_ns.len - 1]

		// common changes
		out_stmt = match first_ns {
			'len', 'cap', 'rune', 'string' { v.style_fn_to_decl(stmt, first_ns) }
			'make' { v.style_make(stmt) }
			'delete' { v.style_delete(stmt) }
			'strings' { v.style_strings_module(stmt, last_ns) }
			'fmt' { v.style_print(stmt, last_ns) }
			else { stmt }
		}
		// string builders
		if v.string_builder_vars.contains(all_but_last_ns)
			&& transpiler.string_builder_diffs.contains(last_ns) {
			out_stmt = v.style_string_builder(stmt, all_but_last_ns, last_ns)
		}
	} else if stmt is VariableStmt {
		mut temp_stmt := stmt
		mut multiple_stmt := MultipleStmt{}

		for i, mut value in temp_stmt.values {
			v.current_var_name = stmt.names[i]
			value = v.style_stmt(value)

			// `append(array, value)` -> `array << value`
			// `append(array, value1, value2)` -> `array << [value1, value2]`
			if mut value is CallStmt {
				if value.namespaces == 'append' {
					// single
					if value.args.len < 3 {
						multiple_stmt.stmts << PushStmt{
							stmt: BasicValueStmt{stmt.names[i]}
							value: value.args[1]
						}
						// multiple
					} else {
						mut push_stmt := PushStmt{
							stmt: BasicValueStmt{stmt.names[i]}
						}
						mut array := ArrayStmt{}

						for arg in value.args[1..] {
							array.values << arg
						}
						push_stmt.value = array

						multiple_stmt.stmts << push_stmt
					}

					temp_stmt.names.delete(i)
					temp_stmt.values.delete(i)
				}
			}
		}

		// clear now empty variable stmts
		if stmt.names.len > 0 {
			multiple_stmt.stmts << temp_stmt
		}

		out_stmt = multiple_stmt
	} else if stmt is DeferStmt {
		// `defer func()` -> `defer { func() }`
		out_stmt = DeferStmt{v.style_stmt(stmt.stmt)}
	} else if stmt is MatchStmt {
		//	switch variable {
		//	case "a", "b", "c", "d":
		//		return true
		//	}
		// ->
		//	if ['a', 'b', 'c', 'd'].includes(variable) {
		//		return true
		//	}
		if stmt.cases.len == 2 && stmt.cases[1].body.len == 0 {
			array := ArrayStmt{
				values: stmt.cases[0].values
			}

			out_stmt = IfStmt{[
				IfElse{
					condition: '${v.stmt_to_string(array)}.includes(${v.stmt_to_string(stmt.value)})'
					body: stmt.cases[0].body
				},
			]}
		}
	} else if stmt is ComplexValueStmt {
		// `bytes.Buffer{}` -> `strings.new_builder()`
		// `strings.Buffer{}` -> `strings.new_builder()`
		if stmt.value is StructStmt {
			if stmt.value.name == 'bytes.Buffer' || stmt.value.name == 'strings.Builder' {
				out_stmt = CallStmt{
					namespaces: 'strings.new_builder'
					args: [BasicValueStmt{'0'}]
				}
			}
		}
	}

	return out_stmt
}
