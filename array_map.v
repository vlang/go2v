// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) array_init(c CompositeLit) {
	typ := c.typ
	match typ {
		ArrayType {
			mut have_len := false
			mut len_val := ''
			mut is_fixed := false
			if typ.len is BasicLit {
				is_fixed = typ.len.value != ''
				have_len = typ.len.value != ''
				len_val = typ.len.value
			} else if typ.len is Ellipsis {
				is_fixed = true
			}
			mut elt_name := ''
			match typ.elt {
				Ident {
					elt_name = go2v_type(typ.elt.name)
				}
				StarExpr {
					x := typ.elt.x
					match x {
						Ident {
							elt_name = go2v_type(x.name)
						}
						else {}
					}
				}
				else {}
			}
			// No elements, just `[]bool{}` (specify type)
			if c.elts.len == 0 {
				app.gen('[')
				if have_len {
					app.gen(len_val)
				}
				app.gen(']')
				app.gen(elt_name)
				app.gen('{}')
			} else {
				// [1,2,3]
				app.gen('[')
				for i, elt in c.elts {
					if i == 0 && elt_name != '' && elt_name != 'string'
						&& !elt_name.starts_with_capital() {
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
					diff := len_val.int() - c.elts.len
					if diff > 0 {
						for _ in 0 .. diff {
							app.gen(',')
							match elt_name {
								'isize', 'usize' { app.gen('0') }
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
		else {}
	}
}

fn (mut app App) map_init(node CompositeLit) {
	app.genln('{')
	for elt in node.elts {
		kv := elt as KeyValueExpr
		app.key_value_expr(kv)
	}
	app.gen('}')
}
