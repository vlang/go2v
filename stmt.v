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
		// have to keep track of variable names which match outer scope, so they can be renamed in inner...
		BlockStmt {
			app.block_stmt(stmt)
		}
		BranchStmt {
			app.branch_stmt(stmt)
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
		RangeStmt {
			app.range_stmt(stmt)
		}
		ReturnStmt {
			app.return_stmt(stmt)
		}
		DeferStmt {
			app.defer_stmt(stmt)
		}
		GoStmt {
			app.go_stmt(stmt)
		}
		else {
			app.genln('\t// unhandled in stmt: ${stmt}')
		} // Add additional handlers as needed
	}
}

fn (mut app App) expr_stmt(stmt ExprStmt) {
	app.expr(stmt.x)
}

fn (mut app App) go_stmt(stmt GoStmt) {
	app.gen('go ')
	app.expr(stmt.call)
}

fn (mut app App) block_stmt(body BlockStmt) {
	app.genln('{')
	// println('LIST=')
	// println(body.list)
	app.stmt_list(body.list)
	app.genln('}')
}

fn (mut app App) if_stmt(node IfStmt) {
	if node.init.tok != '' {
		app.assign_stmt(node.init, false)
	}

	app.gen('if ')
	app.expr(node.cond)
	app.block_stmt(node.body)
	// else if ... {
	if node.else_ is IfStmt {
		app.genln('else')
		app.if_stmt(node.else_)
	}
	// else {
	else if node.else_ is BlockStmt {
		app.genln('else')
		app.block_stmt(node.else_)
	}
}

fn (mut app App) for_stmt(f ForStmt) {
	app.gen('for ')
	// println(f)
	// for {}
	// if f.cond == unsafe { nil } {
	//}

	init_empty := f.init.node_type == ''
	cond_empty := f.cond.node_type() == ''

	if init_empty && cond_empty {
		app.block_stmt(f.body)
		return
	}
	// for cond {
	if init_empty && !cond_empty {
		app.expr(f.cond)
		app.block_stmt(f.body)

		return
	}
	// for a;b;c {
	app.assign_stmt(f.init, true)
	app.gen('; ')
	app.expr(f.cond)
	app.gen('; ')
	app.stmt(f.post)
	app.block_stmt(f.body)
}

fn (mut app App) range_stmt(node RangeStmt) {
	app.gen('for ')
	// Both key and value are present
	// if node.key.name != node.value.name {
	if node.key.name == '' {
		app.gen('_ ')
	} else {
		app.gen(app.go2v_ident(node.key.name))
		app.gen(', ')
		if node.value.name == '' {
			app.gen(' _ ')
		} else {
			app.gen(app.go2v_ident(node.value.name))
		}
	}
	app.gen(' in ')
	app.expr(node.x)
	app.gen(' ')
	app.block_stmt(node.body)
}

fn (mut app App) inc_dec_stmt(i IncDecStmt) {
	app.expr(i.x)
	app.gen(i.tok)
}

fn (mut app App) decl_stmt(d DeclStmt) {
	match d.decl {
		GenDecl {
			if d.decl.tok == 'var' {
				for spec in d.decl.specs {
					match spec {
						ValueSpec {
							app.gen('mut ')
							app.gen(spec.names[0].name)
							app.gen(' := ')
							mut kind := 'int'
							if spec.values.len == 0 {
								// app.genln('NO SPEC VALUES')
								// `var x int` declaration without initialization
								app.gen_zero_value(spec.typ)
								continue
							}
							value := spec.values[0]
							match value {
								BasicLit {
									kind = go2v_type(value.kind.to_lower())
									if kind != 'int' {
										app.gen('${kind}(')
									}
								}
								else {}
							}
							app.expr(spec.values[0])
							if kind != 'int' {
								app.gen(')')
							}
						}
						else {
							app.gen('// UNHANDLED DeclStmt-GenDecl spec')
						}
					}
				}
			}
		}
		else {
			app.gen('// UNHANDLED DeclStmt')
		}
	}
	app.genln('')
}

fn (mut app App) defer_stmt(node DeferStmt) {
	// print_backtrace()
	app.gen('defer ')
	// `defer fn() { ... } ()
	// empty function, just generate `defer { ... }` in V

	if node.call is CallExpr && node.call.args.len == 0 {
		if node.call.fun is FuncLit {
			func_lit := node.call.fun as FuncLit
			app.block_stmt(func_lit.body)
		} else {
			app.genln('{')
			app.expr(node.call.fun) // TODO broken no () after foo.bar
			app.genln('}')
			// app.genln('// UNKNOWN node.call.fun ${node.call.fun.type_name()}')
		}
	} else {
		app.genln('{')
		app.expr(node.call)
		app.genln('}')
	}
}

fn (mut app App) return_stmt(node ReturnStmt) {
	app.gen('return ')
	for i, result in node.results {
		app.expr(result)
		if i < node.results.len - 1 {
			app.gen(',')
		}
	}
	app.genln('')
}

// continue break etc
fn (mut app App) branch_stmt(node BranchStmt) {
	app.gen(node.tok)
	if node.label.name != '' {
		app.gen(' ' + node.label.name)
	}
	app.genln('')
}
