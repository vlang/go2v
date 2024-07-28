// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
fn (mut app App) func_decl(decl Decl) {
	method_name := decl.name.name.to_lower()
	mut recv := ''
	if decl.recv.list.len > 0 {
		recv_type := app.type_or_ident(decl.recv.list[0].typ)
		recv_name := decl.recv.list[0].names[0].name
		recv = '(${recv_name} ${recv_type})'
	}
	params := decl.typ.params.list.map(it.names.map(it.name).join(', ') + ' ' +
		app.type_or_ident(it.typ)).join(', ')
	results := if decl.typ.results.list.len > 0 {
		' ${decl.typ.results.list.map(app.type_or_ident(it.typ)).join(', ')}'
	} else {
		''
	}
	if recv != '' {
		app.gen('fn ${recv} ')
	} else {
		app.gen('fn ')
	}
	app.genln('${method_name}(${params})${results}')
	app.block_stmt(decl.body)
}
