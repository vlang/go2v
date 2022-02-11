module transpiler

fn (mut v VAST) v_style() {
	mut fmt_count := 0
	mut println_count := 0

	for mut func in v.functions {
		for mut stmt in func.body {
			if mut stmt is CallStmt {
				// transform `fmt.Println` to `println`
				if stmt.namespaces[0].name == 'fmt' {
					fmt_count++
					if stmt.namespaces[1].name == 'Println' {
						println_count++
						new_ns := Namespace{'println', stmt.namespaces[1].args}
						stmt.namespaces.delete_last()
						stmt.namespaces[0] = new_ns
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
