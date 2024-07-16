fn (mut app App) assign_stmt(assign AssignStmt) {
	// app.genln('//assign_stmt')
	if assign.tok == ':=' {
		app.gen('mut ')
	}
	for i, expr in assign.lhs {
		app.expr(expr)
		if i < assign.lhs.len - 1 {
			app.gen(', ')
		}
	}
	// Special case for 'append()' => '<<'
	if app.check_and_handle_append(assign) {
		return
	}
	//
	app.gen(assign.tok)
	for expr in assign.rhs {
		app.expr(expr)
	}
	app.genln('')
}

fn (mut app App) check_and_handle_append(assign AssignStmt) bool {
	first_rhs := assign.rhs[0]
	if first_rhs is CallExpr {
		fun := first_rhs.fun
		if fun is Ident {
			if fun.name == 'append' {
				app.gen_append(first_rhs.args)
				return true
			}
		}
	}
	return false
}

fn (mut app App) gen_append(args []Expr) {
	app.gen(' << ')
	if args.len == 2 {
		app.expr(args[1])
		app.genln('')
		return
	}

	for i := 1; i < args.len; i++ {
		if i == 1 && args[i] is BasicLit {
			app.gen('[')
		}
		app.expr(args[i])
		if i < args.len - 1 {
			app.gen(',')
		} else if i == args.len - 1 && args[i] is BasicLit {
			app.gen(']')
		}
	}
	app.genln('')
}
