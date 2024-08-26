fn (mut app App) assign_stmt(assign AssignStmt, no_mut bool) {
	// app.genln('//assign_stmt')
	for i, lhs_expr in assign.lhs {
		if i == 0 {
			match lhs_expr {
				Ident {
					if lhs_expr.name != '_' {
						if !no_mut {
							if assign.tok == ':=' {
								app.gen('mut ')
							}
						}
					}
				}
				else {}
			}
		}
		app.expr(lhs_expr)
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
	for rhs_expr in assign.rhs {
		app.expr(rhs_expr)
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
		arg_i := args[i]
		match arg_i {
			BasicLit {
				v_kind := go2v_type(arg_i.kind.to_lower())
				needs_cast := v_kind != 'int'
				if i == 1 {
					app.gen('[')
					if needs_cast {
						app.gen('${go2v_type(v_kind)}(')
					}
				}
				app.expr(arg_i)
				if i == 1 && needs_cast {
					app.gen(')')
				}
				if i < args.len - 1 {
					app.gen(',')
				} else if i == args.len - 1 {
					app.gen(']')
				}
			}
			else {
				if i == 1 {
					app.gen('[')
				}
				app.expr(arg_i)
				if i < args.len - 1 {
					app.gen(',')
				} else if i == args.len - 1 {
					app.gen(']')
				}
			}
		}
	}
	app.genln('')
}
