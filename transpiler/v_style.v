module transpiler

fn (mut v VAST) v_style() {
	// TODO: refactor this as it doesn't work on non-function bodies
	mut fmt_count := 0
	mut println_count := 0

	for mut func in v.functions {
		for mut stmt in func.body {
			if mut stmt is CallStmt {
				// transform `fmt.Println` to `println`
				ns_arr := stmt.namespaces.split('.')
				if ns_arr[0] == 'fmt' {
					fmt_count++
					if ns_arr[1] == 'println' {
						println_count++
						stmt.namespaces = 'println'
					}
				}
			}
		}
	}

	// transform `fmt.Println` to `println`
	if fmt_count == println_count && fmt_count > 0 {
		if v.imports.contains('fmt') {
			v.imports.delete(v.imports.index('fmt'))
		}
	}
}
