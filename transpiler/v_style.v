module transpiler

fn (mut v VAST) stmt_to_string(stmt Statement) string {
	v.handle_stmt(stmt, true)
	return v.out.cut_last(v.out.len)
}

fn (mut v VAST) style_print(stmt CallStmt) CallStmt {
	mut s := stmt

	ns_array := s.namespaces.split('.')

	if ns_array[0] == 'fmt' {
		v.fmt_import_count++

		if ns_array[1] == 'println' || ns_array[1] == 'print' {
			v.fmt_supported_fn_count++
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

fn (mut v VAST) v_style(body []Statement) []Statement {
	mut b := body.clone()

	for i, stmt in b {
		if mut stmt is CallStmt {
			// `len(array)` -> `array.len`
			// `cap(array)` -> `array.cap`
			if stmt.namespaces == 'len' || stmt.namespaces == 'cap' {
				b.delete(i)
				b.insert(i, BasicValueStmt{'${v.stmt_to_string(stmt.args[0])}.$stmt.namespaces'})
				// `make(map[string]int)` -> `map[string]int{}`
			} else if stmt.namespaces == 'make' {
				b.delete(i)
				b.insert(i, BasicValueStmt{'${v.stmt_to_string(stmt.args[0])}{}'})
				// `delete(map, key)` -> `map.delete(key)`
			} else if stmt.namespaces == 'delete' {
				b.delete(i)
				b.insert(i, CallStmt{
					namespaces: '${v.stmt_to_string(stmt.args[0])}.delete'
					args: [stmt.args[1]]
				})
			} else {
				// `fmt.println(a)` -> `println(a)`
				temp := v.style_print(stmt)
				stmt.namespaces = temp.namespaces
				stmt.args = temp.args
			}
			// `append(array, value)` -> `array << value`
		} else if mut stmt is VariableStmt {
			mut push_stmts := []PushStmt{}

			for j, value in stmt.values {
				if value is CallStmt {
					if value.namespaces == 'append' {
						// `append(array, value)` -> `array << value`
						if value.args.len < 3 {
							push_stmts << PushStmt{
								stmt: BasicValueStmt{stmt.names[j]}
								value: value.args[1]
							}
							// `append(array, value1, value2)` -> `array << [value1, value2]`
						} else {
							mut push_stmt := PushStmt{
								stmt: BasicValueStmt{stmt.names[j]}
							}
							mut array := ArrayStmt{}

							for el in value.args[1..] {
								array.values << el
							}
							push_stmt.value = array

							push_stmts << push_stmt
						}

						stmt.names.delete(j)
						stmt.values.delete(j)
					}
				}
			}

			// delete now empty variable statement
			if stmt.names.len == 0 {
				b.delete(i)
			}

			for push_stmt in push_stmts {
				b.insert(i, push_stmt)
			}
			// `defer func()` -> `defer { func() }`
		} else if mut stmt is DeferStmt {
			if mut stmt.value is CallStmt {
				stmt.value = v.style_print(stmt.value)
			}
		}
	}

	return b
}
