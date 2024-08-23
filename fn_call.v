// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) call_expr(call CallExpr) {
	// app.genln('// cal_expr')
	mut fn_name := ''
	mut is_println := false

	// fmt.Println => println
	fun := call.fun
	if fun is SelectorExpr {
		if fun.x is Ident {
			if fun.x.name == 'fmt' && fun.sel.name in ['Println', 'Print'] {
				fn_name = fun.sel.name.to_lower()
				is_println = true
			} else if fun.sel.name == 'len' {
				app.genln('LEN')
			}
		}
	} else if fun is Ident {
		if fun.name in ['len', 'cap'] {
			// app.expr(first_rhs.args[0])
			app.expr(call.args[0])
			app.gen('.')
			app.gen(fun.name)
			return
		} else if fun.name == 'new' {
			// new(Foo) => &Foo{}
			app.gen('&')
			app.expr(call.args[0])
			app.gen('{}')
			return
		}
		// println('FUN')
		// println(fun)
	}

	// []byte(str) => str.bytes()
	if fun is ArrayType {
		elt := fun.elt
		if elt is Ident && elt.name == 'byte' {
			x := call.args[0]
			if x is BasicLit {
				app.expr(x)
				app.gen('.bytes()')
				return
			}
		}
	}

	if fun is Ident && fun.name == 'delete' {
		arg0 := call.args[0]
		match arg0 {
			Ident {
				app.gen('${arg0.name}')
			}
			SelectorExpr {
				app.expr(arg0)
			}
			else {
				app.gen('// UNHANDLED delete type')
			}
		}
		app.gen('.${fun.name}(')
		app.expr(call.args[1])
		app.genln(')')
		return
	}

	if !is_println {
		// app.is_fn_call = true
		// app.expr(fun)
		// app.is_fn_call = false
		// app.force_lower = true
		if fun is SelectorExpr {
			// Custom selector expr fn for lower case
			app.selector_expr_fn_call(call, fun) // fun)
		} else {
			app.expr(fun)
		}
	}

	app.gen('${fn_name}(') // fn_name is empty unless print

	// In V println can only accept one argument, so convert multiple arguments into a single string
	// with concatenation:
	// `println(a, b)` => `println('${a} ${b}')`
	if is_println && call.args.len > 1 {
		app.gen("'")
		for i, arg in call.args {
			is_string_lit := arg is BasicLit && arg.kind == 'STRING'
			// println('arg=${arg}')
			if is_string_lit {
				// 'foo=${bar}` instead of '${"foo"}=${bar}'
				lit := arg as BasicLit
				app.gen(lit.value[1..lit.value.len - 1])
			} else {
				app.gen('\${')
				app.expr(arg)
				app.gen('}')
			}
			if i < call.args.len - 1 {
				app.gen(' ')
			}
		}
		app.gen("'")
		app.genln(')')
		return
	}

	for i, arg in call.args {
		if app.skip_first_arg {
			app.skip_first_arg = false
			continue
		}
		app.expr(arg)
		if i < call.args.len - 1 {
			app.gen(', ')
		}
	}
	app.genln(')')
}

const unexisting_modules = ['fmt', 'path', 'strings']

fn (mut app App) selector_expr_fn_call(call CallExpr, sel SelectorExpr) {
	// app.genln('///selector_expr_fn_call')
	if sel.x is Ident {
		if sel.x.name in unexisting_modules {
			app.handle_nonexistent_module_call(sel.x.name, sel.sel.name, call)
			return
		}
	}
	app.expr(sel.x)
	app.gen('.')
	app.gen(sel.sel.name.to_lower())
}

fn (mut app App) handle_nonexistent_module_call(mod_name string, fn_name string, node CallExpr) {
	// println('nonexistent module "${mod_name}" node=${node}')
	match mod_name {
		'strings' {
			app.handle_strings_call(app.go2v_ident(fn_name), node.args)
		}
		'path' {
			app.handle_path_call(app.go2v_ident(fn_name), node.args)
		}
		else {}
	}
}

// strings functions are defined as string methods in V
fn (mut app App) handle_strings_call(fn_name string, args []Expr) {
	app.expr(args[0])
	app.gen('.')
	app.gen(fn_name)
	app.skip_first_arg = true
}

fn (mut app App) handle_path_call(fn_name string, args []Expr) {
	// path.Base => os.base
	if fn_name == 'base' {
		app.gen('os.base')
	}
}
