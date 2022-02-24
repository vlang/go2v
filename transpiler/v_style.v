module transpiler

fn (mut v VAST) v_style(body []Statement) []Statement {
	mut b := body.clone()

	for stmt in b {
		if mut stmt is CallStmt {
			ns_array := stmt.namespaces.split('.')

			if ns_array[0] == 'fmt' {
				v.fmt_import_count++

				if ns_array[1] == 'println' {
					v.println_fn_count++
					stmt.namespaces = 'println'

					// `fmt.Println(a, b)` -> `println('${a} ${b}')`
					if stmt.args.len > 1 {
						mut out := "'"
						for i, arg in stmt.args {
							v.stmt_str(arg, true)
							out += '\${${v.out.cut_last(v.out.len)}}'
							out += if i != stmt.args.len - 1 { ' ' } else { "'" }
						}
						stmt.args = [BasicValueStmt{out}]
					}
				}
			}
		}
	}

	return b
}
