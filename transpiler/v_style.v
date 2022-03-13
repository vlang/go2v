module transpiler

const strings_to_builtin = ['compare', 'contains', 'contains_any', 'count', 'fields', 'index',
	'index_any', 'index_byte', 'last_index', 'last_index_byte', 'repeat', 'split', 'title',
	'to_lower', 'to_upper', 'trim', 'trim_left', 'trim_prefix', 'trim_right', 'trim_space',
	'trim_suffix']

fn (mut v VAST) stmt_to_string(stmt Statement) string {
	v.handle_stmt(stmt, true)
	return v.out.cut_last(v.out.len)
}

fn (mut v VAST) style_print(stmt CallStmt) CallStmt {
	mut s := stmt

	ns_array := s.namespaces.split('.')

	if ns_array[0] == 'fmt' {
		v.imports_count['fmt'][0]++

		if ns_array[1] == 'println' || ns_array[1] == 'print' {
			v.imports_count['fmt'][1]++
			s.namespaces = ns_array[1]

			// `println(a, b)` -> `println('${a} ${b}')`
			if s.args.len > 1 {
				mut out := "'"
				for i, arg in s.args {
					out += '\${${v.stmt_to_string(arg)}}'
					out += if i != s.args.len - 1 { ' ' } else { "'" }
				}
				s.args = [BasicValueStmt{out}]
			}
		}
	}

	return s
}

fn (mut v VAST) style_stmt(s Statement) Statement {
	mut stmt := s

	if mut stmt is CallStmt {
		ns := stmt.namespaces.split('.')

		// `len(array)` -> `array.len`
		// `cap(array)` -> `array.cap`
		if stmt.namespaces == 'len' || stmt.namespaces == 'cap' {
			stmt = BasicValueStmt{'${v.stmt_to_string(stmt.args[0])}.$stmt.namespaces'}
			// `make(map[string]int)` -> `map[string]int{}`
		} else if stmt.namespaces == 'make' {
			stmt = BasicValueStmt{'${v.stmt_to_string(stmt.args[0])}{}'}
			// `delete(map, key)` -> `map.delete(key)`
		} else if stmt.namespaces == 'delete' {
			stmt = CallStmt{
				namespaces: '${v.stmt_to_string(stmt.args[0])}.delete'
				args: [stmt.args[1]]
			}
		} else if ns[0] == 'strings' {
			v.imports_count['strings'][0]++
			if transpiler.strings_to_builtin.contains(ns[1]) {
				v.imports_count['strings'][1]++
				if stmt.args.len == 1 {
					stmt = CallStmt{
						namespaces: '${v.stmt_to_string(stmt.args[0])}.${ns[1]}'
					}
				} else {
					stmt = CallStmt{
						namespaces: '${v.stmt_to_string(stmt.args[0])}.${ns[1]}'
						args: [stmt.args[1]]
					}
				}
			}
		} else if stmt.namespaces == 'rune' {
			stmt = CallStmt{
				namespaces: '${v.stmt_to_string(stmt.args[0])}.runes'
			}
		} else {
			// `fmt.println(a)` -> `println(a)`
			stmt = v.style_print(stmt)
		}
		// `append(array, value)` -> `array << value`
	} else if mut stmt is VariableStmt {
		mut push_stmts := []PushStmt{}

		for i, value in stmt.values {
			if value is CallStmt {
				if value.namespaces == 'append' {
					// `append(array, value)` -> `array << value`
					if value.args.len < 3 {
						push_stmts << PushStmt{
							stmt: BasicValueStmt{stmt.names[i]}
							value: value.args[1]
						}
						// `append(array, value1, value2)` -> `array << [value1, value2]`
					} else {
						mut push_stmt := PushStmt{
							stmt: BasicValueStmt{stmt.names[i]}
						}
						mut array := ArrayStmt{}

						for el in value.args[1..] {
							array.values << el
						}
						push_stmt.value = array

						push_stmts << push_stmt
					}

					stmt.names.delete(i)
					stmt.values.delete(i)
				}
			}
		}

		mut temp_stmt := MultipleStmt{}
		if stmt.names.len != 0 {
			temp_stmt.stmts << stmt
		}
		for push_stmt in push_stmts {
			temp_stmt.stmts << push_stmt
		}
		stmt = temp_stmt

		// `defer func()` -> `defer { func() }`
	} else if mut stmt is DeferStmt {
		if mut stmt.value is CallStmt {
			stmt.value = v.style_print(stmt.value)
		}
	} else if mut stmt is MatchStmt {
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

			stmt = IfStmt{[
				IfElse{
					condition: '${v.stmt_to_string(array)}.includes(${v.stmt_to_string(stmt.value)})'
					body: stmt.cases[0].body
				},
			]}
		}
	}

	return stmt
}
