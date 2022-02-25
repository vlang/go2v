module transpiler

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
					v.handle_stmt(arg, true)
					out += '\${${v.out.cut_last(v.out.len)}}'
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

	for stmt in b {
		if mut stmt is CallStmt {
			temp := v.style_print(stmt)
			stmt.namespaces = temp.namespaces
			stmt.args = temp.args
		} else if mut stmt is DeferStmt {
			if mut stmt.value is CallStmt {
				stmt.value = v.style_print(stmt.value)
			}
		}
	}

	return b
}
