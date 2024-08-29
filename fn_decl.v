// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) func_decl(decl FuncDecl) {
	app.comments(decl.doc)
	method_name := decl.name.name.to_lower()
	// Capital? Then it's public in Go
	is_pub := decl.name.name[0].is_capital()
	if is_pub {
		app.gen('pub ')
	}
	// println('FUNC DECL ${method_name}')

	// mut recv := ''
	// if decl.recv.list.len > 0 {
	// recv_type := type_or_ident(decl.recv.list[0].typ)
	// recv_name := decl.recv.list[0].names[0].name
	// recv = '(${recv_name} ${recv_type})'
	//}
	// params := decl.typ.params.list.map(it.names.map(it.name).join(', ') + ' ' +
	// type_or_ident(it.typ)).join(', ')
	// if recv != '' {
	if decl.recv.list.len > 0 {
		// app.gen('fn ${recv} ')
		app.gen('fn (')
		if decl.recv.list[0].names.len == 0 {
			app.is_mut_recv = true
			app.gen('mut _ ')
		} else {
			recv_name := decl.recv.list[0].names[0].name

			app.gen(recv_name + ' ')
		}
		app.typ(decl.recv.list[0].typ)
		app.gen(') ')
	} else {
		app.gen('fn ')
	}
	app.gen(method_name)
	app.func_params(decl.typ.params)
	app.func_return_type(decl.typ.results)
	app.block_stmt(decl.body)
}

fn (mut app App) func_type(t FuncType) {
	app.func_params(t.params)
	app.func_return_type(t.results)
}

fn (mut app App) func_return_type(results FieldList) {
	// app.genln(results)
	// Return types
	return_types := results.list
	if return_types.len > 1 {
		app.gen('(')
	}
	for i, res in return_types {
		app.typ(res.typ)
		if i < return_types.len - 1 {
			app.gen(',')
		}
		//' ${decl.typ.results.list.map(type_or_ident(it.typ)).join(', ')}'
	}
	if return_types.len > 1 {
		app.gen(')')
	}
}

fn (mut app App) func_params(params FieldList) {
	// p := params.list.map(it.names.map(it.name).join(', ') + ' ' + type_or_ident(it.typ)).join(', ')
	app.gen('(')
	// app.gen(p)
	// println(app.sb.str())
	for i, param in params.list {
		for j, name in param.names {
			app.gen(name.name)
			app.gen(' ')
			app.typ(param.typ)
			if j < param.names.len - 1 {
				app.gen(',')
			}
		}
		// app.gen(type_or_ident(param.typ))
		if i < params.list.len - 1 {
			app.gen(',')
		}
	}
	app.gen(')')
}

fn (mut app App) comments(doc Doc) {
	if doc.list.len == 0 {
		return
	}
	for x in doc.list {
		app.genln(x.text)
	}
}

fn (mut app App) func_lit(node FuncLit) {
	app.gen('fn')
	app.func_params(node.typ.params)
	app.block_stmt(node.body)
}
