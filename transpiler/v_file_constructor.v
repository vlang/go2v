module transpiler

fn v_file_constructor(v_ast VAST) string {
	mut v := v_ast
	v.handle_module()
	v.handle_imports()
	v.handle_types()
	v.handle_structs()
	v.handle_consts()
	v.handle_enums()
	v.handle_functions()

	// remove last newline
	v.out.cut_last(1)

	return v.out.str()
}

fn (mut v VAST) handle_module() {
	v.out.writeln('module ${v.@module}')
	v.out.write_rune(`\n`)
}

fn (mut v VAST) handle_imports() {
	len := v.out.len
	for imp in v.imports {
		// remove useless `fmt` import
		if !(imp == 'fmt' && v.fmt_import_count == v.println_fn_count) {
			v.out.writeln('import $imp')
		}
	}
	if len != v.out.len {
		v.out.write_rune(`\n`)
	}
}

fn (mut v VAST) handle_types() {
	if v.types.len != 0 {
		for name, typ in v.types {
			v.out.writeln('type $name = $typ')
		}
		v.out.write_rune(`\n`)
	}
}

fn (mut v VAST) handle_structs() {
	for strct in v.structs {
		v.out.write_string('struct $strct.name {')
		if strct.fields.len != 0 {
			for field, typ in strct.fields {
				v.out.write_string('\n\t$field $typ')
			}
			v.out.write_string('\n}')
		} else {
			v.out.write_string('}')
		}
		v.out.writeln('\n')
	}
}

fn (mut v VAST) handle_consts() {
	if v.consts.len != 0 {
		if v.consts.len == 1 {
			key := v.consts.keys()[0]
			v.out.writeln('const $key = ${v.consts[key]}')
		} else {
			v.out.writeln('const (')
			for key, val in v.consts {
				v.out.writeln('\t$key = $val')
			}
			v.out.writeln(')')
		}
		v.out.write_rune(`\n`)
	}
}

fn (mut v VAST) handle_enums() {
	for enm in v.enums {
		v.out.writeln('enum $enm.name {')
		for name, val in enm.fields {
			if val.len == 0 {
				v.out.writeln('\t$name')
			} else {
				v.out.writeln('\t$name = $val')
			}
		}
		v.out.writeln('}\n')
	}
}

fn (mut v VAST) handle_functions() {
	for func in v.functions {
		// comment
		if func.comment != '' {
			v.out.writeln(func.comment)
		}
		// public/private
		if func.public {
			v.out.write_string('pub ')
		}
		// keyword
		v.out.write_string('fn ')
		// method
		if func.method.len != 0 {
			v.out.write_string('(${func.method[0]} ${func.method[1]}) ')
		}
		// name
		v.out.write_string('${func.name}(')
		// arguments
		mut len := func.args.len
		for name, @type in func.args {
			len--
			if len == 0 {
				v.out.write_string('$name ${@type}')
			} else {
				v.out.write_string('$name ${@type}, ')
			}
		}
		v.out.write_string(')')
		// return value(s)
		if func.ret_vals.len == 1 {
			v.out.write_string(' ${func.ret_vals[0]}')
		} else if func.ret_vals.len != 0 {
			v.out.write_string(' (')
			len = func.ret_vals.len
			for i, val in func.ret_vals {
				if i != len - 1 {
					v.out.write_string('$val, ')
				} else {
					v.out.write_string('$val')
				}
			}
			v.out.write_string(')')
		}
		// body
		if func.body.len != 0 {
			v.out.write_string(' {\n')
		} else {
			v.out.write_string(' {')
		}
		v.handle_body(func.body)
		v.out.write_string('}\n\n')
	}
}

fn (mut v VAST) handle_body(body []Statement) {
	v.indent += '\t'

	for stmt in body {
		v.stmt_str(stmt, false)
	}

	v.indent = v.indent#[..-1]
}

fn (mut v VAST) stmt_str(stmt Statement, is_value bool) {
	if !is_value {
		v.out.write_string(v.indent)
	}
	match stmt {
		VariableStmt {
			stop := stmt.names.len - 1

			if stmt.mutable && stmt.middle == ':=' {
				v.out.write_string('mut ')
			}

			for i, name in stmt.names {
				comma := if i != stop { ',' } else { '' }
				v.out.write_string('$name$comma ')
			}
			v.out.write_string(stmt.middle)
			for i, value in stmt.values {
				comma := if i != stop { ',' } else { '' }
				v.out.write_rune(` `)
				v.stmt_str(value, true)
				v.out.write_string(comma)
			}
		}
		IncDecStmt {
			v.out.write_string('$stmt.var$stmt.inc')
		}
		CallStmt {
			stop := stmt.args.len - 1

			v.out.write_string('${stmt.namespaces}(')
			for i, arg in stmt.args {
				v.stmt_str(arg, true)
				v.out.write_string(if i != stop { ', ' } else { '' })
			}
			v.out.write_rune(`)`)
		}
		IfStmt {
			for i, branch in stmt.branchs {
				if i != 0 {
					v.out.write_string('else ')
				}
				if branch.condition != ' ' {
					v.out.write_string('if $branch.condition ')
				}
				v.out.writeln('{')
				v.handle_body(branch.body)
				v.out.write_string(v.indent)
				if i != stmt.branchs.len - 1 {
					v.out.write_string('} ')
				} else {
					v.out.write_string('}')
				}
			}
		}
		ForStmt {
			v.out.write_string('for ')
			// check if stmt.init or stmt.post aren't null
			if stmt.init.names.len > 0 || stmt.post.type_name() != 'unknown transpiler.Statement' {
				// c-style for
				v.stmt_str(stmt.init, true)
				v.out.write_string('; $stmt.condition; ')
				v.stmt_str(stmt.post, true)
				// check if stmt.post isn't null
				if stmt.post.type_name() != 'unknown transpiler.Statement' {
					v.out.write_rune(` `)
				}
			} else if stmt.condition[0] != ` ` {
				// while
				v.out.write_string('$stmt.condition ')
			}
			// for bare loops no need to write anything
			v.out.write_string('{\n')
			v.handle_body(stmt.body)
			v.out.write_string('$v.indent}')
		}
		ForInStmt {
			if stmt.idx.len > 0 || stmt.element.len > 0 {
				v.out.write_string('for $stmt.idx, $stmt.element in ')
			} else {
				v.out.write_string('for _ in ')
			}
			v.stmt_str(stmt.variable, true)
			v.out.write_string(' {\n')
			v.handle_body(stmt.body)
			v.out.write_string('$v.indent}')
		}
		BranchStmt {
			v.out.write_string(stmt.name)
		}
		ArrayStmt {
			is_empty := stmt.values.len < 1
			is_fixed_size := stmt.len.len > 0

			v.out.write_rune(`[`)

			if is_empty {
				if is_fixed_size {
					v.out.write_string(stmt.len)
				}
				v.out.write_string(']${stmt.@type}{}')
			} else {
				mut i := 0
				for el in stmt.values {
					if i != stmt.values.len - 1 {
						v.out.write_string('$el, ')
					} else {
						v.out.write_string('$el')
					}
					i++
				}

				if is_fixed_size && i < stmt.len.int() {
					default_val := match stmt.@type {
						'string' { "''" }
						'int' { '0' }
						'bool' { 'false' }
						else { '${stmt.@type}{}' } // TODO: ensure it is correct
					}

					for i != stmt.len.int() {
						v.out.write_string(', $default_val')
						i++
					}
				}

				v.out.write_rune(`]`)
				if is_fixed_size {
					v.out.write_rune(`!`)
				}
			}
		}
		BasicValueStmt {
			v.out.write_string(stmt.value)
		}
		SliceStmt {
			v.out.write_string('$stmt.value[${stmt.low}..$stmt.high]')
		}
		NotImplYetStmt {}
	}

	if !is_value {
		v.out.write_rune(`\n`)
	}
}
