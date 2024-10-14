// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) unique_name_anti_shadow(n string) string {
	if n == '_' {
		return '_'
	}
	if app.running_test {
		return n
	}
	if n !in app.cur_fn_names {
		return n
	}
	// Increase the i in `name_i` until it's unique.
	mut i := 1
	mut res := ''
	for {
		res = '${n}_${i}'

		if res !in app.cur_fn_names {
			break
		}
		i++
		if i > 100 {
			panic('100 levels of shadowing, that cannot be real!')
		}
	}
	// res := n + rand.intn(10000) or { 0 }.str() // LOL fix this
	return res
}

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
				n = app.unique_name_anti_shadow(n)
			}
			app.cur_fn_names[n] = true

			new_ident := Ident{
				...lhs_expr
				name: n
			}
			// app.ident(app.go2v_ident(new_ident))
			app.ident(new_ident)
		} else if lhs_expr is StarExpr {
			// Can't use star_expr(), since it generates &
			app.gen('*')
			app.expr(lhs_expr.x)
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
	// app.gen('/*F*/')
	for r_idx, rhs_expr in assign.rhs {
		// app.genln('/* ${rhs_expr} */')
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
	if assign.rhs.len == 0 {
		app.genln('// append no rhs')
		return false
	}
	first_rhs := assign.rhs[0]
	if first_rhs is CallExpr {
		fun := first_rhs.fun
		if fun is Ident {
			if fun.name == 'append' {
				app.gen_append(first_rhs.args, assign.tok)
				return true
			}
		}
	}
	return false
}

fn (mut app App) gen_append(args []Expr, assign_tok string) {
	// Handle special case `mut x := arr.clone()`
	// In Go it's
	// `append([]Foo{}, foo...)`

	arg0 := args[0]
	if arg0 is CompositeLit && arg0.typ is ArrayType {
		app.gen(' ${assign_tok} ')
		app.expr(args[1])
		app.gen('.')
		app.genln('clone()')
		return
	}

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
