// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) gen_decl_stmt(stmt Stmt) {
	// for decl in stmt.decls {
	// app.gen_decl(decl)
	//}
}

fn (mut app App) gen_decl(decl Decl) {
	if decl.tok == 'const' {
		// app.genln('//constb')
		app.const_block(decl)
		return
	}
	// is_enum_decl := decl.specs[0].node_type_str == 'TypeSpec' && decl.
	for spec in decl.specs {
		if spec.node_type_str == 'TypeSpec' {
			if spec.typ.node_type_str == 'StructType' {
				app.struct_decl(spec)
			} else if spec.typ.node_type_str == 'InterfaceType' {
				app.interface_decl(spec)
			} else {
				app.type_decl(spec)
			}
		} else if spec.node_type_str == 'ImportSpec' && spec.path.value != '' {
			app.import_spec(spec)
		} else if spec.node_type_str == 'ValueSpec' {
			app.const_decl(spec)
		}
	}
}

fn (mut app App) type_decl(spec Spec) {
	// Remember the type name for the upcoming const (enum) handler
	app.type_decl_name = spec.name.name
}

fn (mut app App) const_block(decl Decl) {
	for spec in decl.specs {
		app.const_decl(spec)
	}
	if decl.specs.len > 1 && app.is_enum_decl {
		app.genln('}')
		app.is_enum_decl = false
	}
}

fn (mut app App) const_decl(spec Spec) {
	// Handle iota (V enuma)
	if spec.values.len > 0 {
		first_val := spec.values[0]
		if first_val is Ident {
			if first_val.name == 'iota' {
				//}
				// if spec.values[0].name == 'iota' {
				app.is_enum_decl = true
				app.genln('enum ${app.type_decl_name} {')
				// for i, name in spec.names {
				// app.genln(app.go2v_ident(name.name))
				//}
				// app.genln('}')
				// return
			}
		}
	}
	// app.genln('// const')
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

fn (mut app App) import_spec(spec Spec) {
	name := spec.path.value.replace('"', '').replace('/', '.')
	// Skip modules that don't exist in V (fmt, strings etc)
	if name in unexisting_modules {
		return
	}
	app.genln('import ${name}')
}

fn (mut app App) struct_decl(spec Spec) {
	struct_name := spec.name.name
	app.genln('struct ${struct_name} {')
	struct_type := spec.typ as StructType
	if struct_type.fields.list.len > 0 {
		app.genln('pub mut:')
	}
	for field in struct_type.fields.list {
		// type_name := type_or_ident(field.typ)
		for n in field.names {
			// app.genln('\t${go2v_ident(n.name)} ${go2v_type(type_name)}')
			app.gen('\t')
			// app.force_upper = true
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

fn (mut app App) interface_decl(spec Spec) {
}

fn (mut app App) composite_lit(c CompositeLit) {
	if c.typ.name != '' {
		app.struct_init(c)
		return
	}
	match c.typ.node_type_str {
		'ArrayType' {
			app.array_init(c)
		}
		'MapType' {
			app.map_init(c)
		}
		else {
			app.gen('// UNHANDLED CompositeLit type')
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
