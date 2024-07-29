module main

fn (mut app App) array_init(c CompositeLit) {
	mut have_len := false
	mut len_val := ''
	mut is_fixed := false
	if c.typ.len is BasicLit {
		is_fixed = c.typ.len.value != ''
		have_len = c.typ.len.value != ''
		len_val = c.typ.len.value
	} else if c.typ.len is Ellipsis {
		is_fixed = true
	}
	// No elements, just `[]bool{}` (specify type)
	if c.elts.len == 0 {
		app.gen('[')
		if have_len {
			app.gen(len_val)
		}
		app.gen(']')
		app.gen(c.typ.elt.name)
		app.gen('{}')
	} else {
		// [1,2,3]
		app.gen('[')
		for i, elt in c.elts {
			elt_name := go2v_type(c.typ.elt.name)
			if i == 0 && is_fixed && elt_name != '' && elt_name != 'string' && elt_name != 'int' {
				// specify type in the first element
				// [u8(1), 2, 3]
				app.gen('${elt_name}(')
				app.expr(elt)
				app.gen(')')
			} else {
				app.expr(elt)
			}
			if i < c.elts.len - 1 {
				app.gen(',')
			}
		}
		if have_len {
			elt_name := go2v_type(c.typ.elt.name)
			diff := len_val.int() - c.elts.len
			if diff > 0 {
				for _ in 0 .. diff {
					app.gen(',')
					match elt_name {
						'int' { app.gen('0') }
						'string' { app.gen("''") }
						else { app.gen('unknown element type??') }
					}
				}
			}
		}
		app.gen(']')
		if is_fixed {
			app.gen('!')
		}
	}
}

fn (mut app App) map_init(node CompositeLit) {
	app.genln('{')
	for elt in node.elts {
		kv := elt as KeyValueExpr
		app.key_value_expr(kv)
	}
	app.genln('}')
}
