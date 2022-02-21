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

					// `println(a, b)` -> `println('$a $b')
					if stmt.args.len > 1 {
						mut out := "'"
						for i, arg in stmt.args {
							// `${}` syntax for special characters
							mut special_char := false
							for ch in arg {
								if !((`a` <= ch && ch <= `z`)
									|| (`A` <= ch && ch <= `Z`) || ch == `.`) {
									special_char = true
									break
								}
							}
							if special_char {
								out += '\${$arg}'
							} else {
								out += '\$$arg'
							}

							if i != stmt.args.len - 1 {
								out += ' '
							} else {
								out += "'"
							}
						}
						stmt.args = [out]
					}
				}
			}
		}
	}

	return b
}
