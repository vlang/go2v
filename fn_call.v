// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) call_expr(call CallExpr) {
	mut fn_name := ''
	mut is_println := false

	// fmt.Println => println
	fun := call.fun
	if fun is SelectorExpr {
		if fun.x is Ident {
			if fun.x.name == 'fmt' && fun.sel.name in ['Println', 'Print'] {
				fn_name = fun.sel.name.to_lower()
				is_println = true
			}
		}
	}

	// []byte(str) => str.bytes()
	if fun is ArrayType && fun.elt.name == 'byte' {
		x := call.args[0]
		if x is BasicLit {
			app.expr(x)
			app.gen('.bytes()')
			return
		}
	}
	if !is_println {
		// app.is_fn_call = true
		// app.expr(fun)
		// app.is_fn_call = false
		if fun is SelectorExpr {
			// Custom selector expr fn for lower case
			app.selector_expr_fn_call(fun)
		} else {
			app.expr(fun)
		}
	}
	app.gen('${fn_name}(')
	// In V println can only accept one argument, so convert multiple argumnents into a single string
	// with concatenation:
	// `println(a, b)` => `println('${a} ${b}')`
	if is_println && call.args.len > 1 {
		app.gen("'")
		for i, arg in call.args {
			app.gen('\${')
			app.expr(arg)
			app.gen('}')
			if i < call.args.len - 1 {
				app.gen(' ')
			}
		}
		app.gen("'")
		app.genln(')')
		return
	}

	for i, arg in call.args {
		app.expr(arg)
		if i < call.args.len - 1 {
			app.gen(', ')
		}
	}
	app.genln(')')
}
