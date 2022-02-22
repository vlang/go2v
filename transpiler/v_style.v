module transpiler

fn (mut v VAST) v_style(body []Statement) []Statement {
	mut b := body.clone()

	for i, stmt in b {
		if mut stmt is CallStmt {
			ns_array := stmt.namespaces.split('.')

			if ns_array[0] == 'fmt' {
				v.fmt_import_count++

				if ns_array[1] == 'println' {
					v.println_fn_count++
					stmt.namespaces = 'println'

					// `fmt.Println(a, b)` -> `println(a)` & `println(b)`
					if stmt.args.len > 1 {
						mut j := i
						for arg in stmt.args {
							j++
							b.insert(j, CallStmt{
								namespaces: 'println'
								args: [arg]
							})
						}
						b.delete(i)
					}
				}
			}
		}
	}

	return b
}
