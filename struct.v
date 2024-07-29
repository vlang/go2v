// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) gen_decl_stmt(stmt Stmt) {
	// for decl in stmt.decls {
	// app.gen_decl(decl)
	//}
}

fn (mut app App) gen_decl(decl Decl) {
	for spec in decl.specs {
		if spec.node_type_str == 'TypeSpec' && spec.typ.node_type_str == 'StructType' {
			app.struct_decl(spec)
		}
	}
}

fn (mut app App) struct_decl(spec Spec) {
	struct_name := spec.name.name
	app.genln('struct ${struct_name} {')
	if spec.typ.fields.list.len > 0 {
		app.genln('pub mut:')
	}
	for field in spec.typ.fields.list {
		type_name := app.type_or_ident(field.typ)
		app.genln('\t${field.names.map(it.name).join(', ')} ${type_name}')
	}
	app.genln('}\n')
}

fn (mut app App) composite_lit(c CompositeLit) {
	if c.typ.name != '' {
		app.struct_init(c)
		return
	}
	if c.typ.node_type_str == 'ArrayType' {
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
}

fn (mut app App) struct_init(c CompositeLit) {
	app.genln('${c.typ.name}{')
	for elt in c.elts {
		app.expr(elt)
		app.genln('')
	}
	app.gen('}')
}
