// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
import rand

fn (mut app App) assign_stmt(assign AssignStmt, no_mut bool) {
	for l_idx, lhs_expr in assign.lhs {
		if l_idx == 0 {
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
		} else {
			app.gen(', ')
		}
		if lhs_expr is Ident {
			// Handle shadowing
			mut n := lhs_expr.name
			if assign.tok == ':=' && n != '_' && n in app.cur_fn_names {
				n += rand.intn(10000) or { 0 }.str() // LOL fix this
			}

			app.cur_fn_names[n] = true
			new_ident := Ident{
				...lhs_expr
				name: n
			}
			app.ident(new_ident) // lhs_expr)
		} else {
			app.expr(lhs_expr)
		}
	}
	// Special case for 'append()' => '<<'
	if app.check_and_handle_append(assign) {
		return
	}
	//
	app.gen(assign.tok)
	for r_idx, rhs_expr in assign.rhs {
		// app.gen('ridx=${r_idx}')
		mut needs_close_paren := false
		if r_idx == 0 {
			rhs := rhs_expr
			match rhs {
				BasicLit {
					if rhs.kind.is_upper() {
						v_kind := go2v_type(rhs.kind.to_lower())
						if v_kind != 'int' && v_kind != 'string' {
							app.gen('${v_kind}(')
							needs_close_paren = true
						}
					}
				}
				else {}
			}
		}
		if r_idx > 0 {
			app.gen(', ')
		}
		app.expr(rhs_expr)
		if needs_close_paren {
			app.gen(')')
		}
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
