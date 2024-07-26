// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) stmt_list(list []Stmt) {
	for stmt in list {
		app.stmt(stmt)
	}
}

fn (mut app App) stmt(stmt Stmt) {
	// app.genln('TYPE = ${stmt.node_type} ${stmt is ExprStmt}')
	// println('FOR STMT')
	// println(stmt)
	match stmt {
		AssignStmt {
			// println('GOT A')
			app.assign_stmt(stmt, false) // no_mut:false
		}
		ExprStmt {
			// app.genln('expr stmt')
			app.expr_stmt(stmt)
		}
		SwitchStmt {
			app.switch_stmt(stmt)
		}
		IfStmt {
			app.if_stmt(stmt)
		}
		ForStmt {
			app.for_stmt(stmt)
		}
		DeclStmt {
			app.decl_stmt(stmt)
		}
		IncDecStmt {
			app.inc_dec_stmt(stmt)
		}
		else {
			app.genln('\t// unhandled in stmt: ${stmt}')
		} // Add additional handlers as needed
	}
	if stmt.node_type_str == 'GenDecl' { //.gen_decl {
		app.gen_decl_stmt(stmt)
		return
	}
}

fn (mut app App) expr_stmt(stmt ExprStmt) {
	app.expr(stmt.x)
}

fn (mut app App) block_stmt(body BlockStmt) {
	app.stmt_list(body.list)
}

fn (mut app App) if_stmt(i IfStmt) {
	app.gen('if ')
	app.expr(i.cond)
	app.genln('{')
	app.block_stmt(i.body)
	app.genln('}')
	// else if ... {
	if i.else_ is IfStmt {
		app.gen('else ')
		app.if_stmt(i.else_)
	}
	// else {
	else if i.else_ is BlockStmt {
		if i.else_.list.len > 0 {
			app.genln('else {')
			app.block_stmt(i.else_)
			app.genln('}')
		}
	}
}

fn (mut app App) for_stmt(f ForStmt) {
	app.gen('for ')
	app.assign_stmt(f.init, true)
	app.gen('; ')
	app.expr(f.cond)
	app.gen('; ')
	app.stmt(f.post)
	app.genln('{')
	app.block_stmt(f.body)
	app.genln('}')
}

fn (mut app App) inc_dec_stmt(i IncDecStmt) {
	app.expr(i.x)
	app.gen(i.tok)
}

fn (mut app App) decl_stmt(d DeclStmt) {
	// app.gen(d.str())
	if d.decl.tok == 'var' {
		app.gen('mut ')
		app.gen(d.decl.specs[0].names[0].name)
		app.gen(' := ')
		typ_name := go2v_type(d.decl.specs[0].typ.name)
		if typ_name != '' {
			app.gen(typ_name)
			app.gen('(')
		}
		app.expr(d.decl.specs[0].values[0])
		if typ_name != '' {
			app.gen(')')
		}
	}
	app.genln('')
}

fn go2v_type(typ string) string {
	if typ == 'byte' {
		return 'u8'
	}
	return typ
}
