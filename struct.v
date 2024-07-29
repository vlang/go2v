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
