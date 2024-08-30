// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) gen_decl(decl GenDecl) {
	mut needs_closer := false
	app.comments(decl.doc)
	for spec in decl.specs {
		match spec {
			ImportSpec {
				app.import_spec(spec)
			}
			TypeSpec {
				match spec.typ {
					InterfaceType {
						app.interface_decl(spec.name.name, spec.typ)
					}
					StructType {
						app.struct_decl(spec.name.name, spec.typ)
					}
					else {
						app.type_decl(spec)
					}
				}
			}
			ValueSpec {
				if spec.typ is Ident {
					needs_closer = true
				}
				match decl.tok {
					'var' {
						app.global_decl(spec)
					}
					else {
						app.const_decl(spec)
					}
				}
			}
		}
	}
	if needs_closer {
		app.genln('}')
	}
}

fn (mut app App) type_decl(spec TypeSpec) {
	// Remember the type name for the upcoming const (enum) handler
	app.type_decl_name = spec.name.name
}

fn (mut app App) global_decl(spec ValueSpec) {
	for name in spec.names {
		app.gen('__global ${name.name} ')
		app.typ(spec.typ)
		app.genln('')
	}
}

fn (mut app App) const_decl(spec ValueSpec) {
	// Handle iota (V enuma)
	if spec.values.len > 0 {
		first_val := spec.values[0]
		if first_val is Ident {
			if first_val.name == 'iota' {
				app.is_enum_decl = true
				app.genln('enum ${app.type_decl_name} {')
			}
		}
	}
	for i, name in spec.names {
		if !app.is_enum_decl && name.name.starts_with_capital() {
			app.gen('pub ')
		}
		n := app.go2v_ident(name.name)
		if app.is_enum_decl {
			if n != 'iota' {
				app.genln(n)
				continue
			}
		} else {
			app.gen('const ${n} = ')
		}
		if i < spec.values.len && !app.is_enum_decl {
			app.expr(spec.values[i])
		}
		app.genln('')
	}
}

fn (mut app App) import_spec(spec ImportSpec) {
	name := spec.path.value.replace('"', '').replace('/', '.')
	// Skip modules that don't exist in V (fmt, strings etc)
	if name in nonexistent_modules {
		return
	}
	app.genln('import ${name}')
}

fn (mut app App) struct_decl(struct_name string, spec StructType) {
	app.genln('struct ${struct_name} {')
	if spec.fields.list.len > 0 {
		app.genln('pub mut:')
	}
	for field in spec.fields.list {
		for n in field.names {
			app.gen('\t')
			app.gen(app.go2v_ident(n.name))
			app.gen(' ')
			app.force_upper = true
			app.typ(field.typ)
			if field.typ is StarExpr {
				app.gen(' = unsafe { nil }')
			}
			app.genln('')
		}
	}
	app.genln('}\n')
}

fn (mut app App) interface_decl(interface_name string, spec InterfaceType) {
	app.genln('interface ${interface_name} {')
	for field in spec.methods.list {
		app.comments(field.doc)
		for n in field.names {
			app.gen('\t')
			app.gen(app.go2v_ident(n.name))
			app.force_upper = true
			app.typ(field.typ)
			app.genln('')
		}
	}
	app.genln('}\n')
}

fn (mut app App) composite_lit(c CompositeLit) {
	// if c.typ.name != '' {
	// 	app.struct_init(c)
	// 	return
	// }
	match c.typ {
		ArrayType {
			app.array_init(c)
		}
		Ident {
			app.struct_init(c)
		}
		MapType {
			app.map_init(c)
		}
		else {
			app.gen('// UNHANDLED CompositeLit type')
		}
	}
}

fn (mut app App) struct_init(c CompositeLit) {
	typ := c.typ
	match typ {
		Ident {
			app.genln('${typ.name}{')
			for elt in c.elts {
				app.expr(elt)
				app.genln('')
			}
			app.gen('}')
		}
		else {}
	}
}
