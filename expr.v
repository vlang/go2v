// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module main

fn (mut app App) expr(expr Expr) {
	match expr {
		BasicLit {
			app.basic_lit(expr)
		}
		BinaryExpr {
			app.binary_expr(expr)
		}
		Ident {
			app.ident(expr)
		}
		CallExpr {
			app.call_expr(expr)
		}
		SelectorExpr {
			app.selector_expr(expr)
		}
		TypeOrIdent {
			type_or_ident(expr)
		}
		CompositeLit {
			app.composite_lit(expr)
		}
		KeyValueExpr {
			app.key_value_expr(expr)
		}
		IndexExpr {
			app.index_expr(expr)
		}
		ParenExpr {
			app.paren_expr(expr)
		}
		UnaryExpr {
			app.unary_expr(expr)
		}
		ArrayType {
			app.array_type(expr)
		}
		StarExpr {
			app.star_expr(expr)
		}
		FuncLit {
			app.func_lit(expr)
		}
		Ellipsis {}
		// else {
		// app.gen('/* UNHANDLED EXPR ${expr.node_type} */')
		//}
	}
}

fn (mut app App) basic_lit(l BasicLit) {
	if l.kind == 'CHAR' {
		app.gen(l.value.replace("'", '`'))
	} else {
		app.gen(l.value)
	}
}

fn (mut app App) selector_expr(s SelectorExpr) {
	force_upper := app.force_upper // save force upper for `mod.ForceUpper`
	app.expr(s.x)
	app.gen('.')
	app.force_upper = force_upper
	app.gen(app.go2v_ident(s.sel.name))
}

fn (mut app App) index_expr(s IndexExpr) {
	app.expr(s.x)
	app.gen('[')
	app.expr(s.index)
	app.gen(']')
}

fn (mut app App) binary_expr(b BinaryExpr) {
	app.expr(b.x)
	if b.op == '\u0026^' {
		app.gen('&~')
	} else {
		app.gen(b.op)
	}
	app.expr(b.y)
}

fn (mut app App) unary_expr(u UnaryExpr) {
	if u.op != '+' {
		app.gen(u.op)
	}
	app.expr(u.x)
}

fn (mut app App) paren_expr(p ParenExpr) {
	app.gen('(')
	app.expr(p.x)
	app.gen(')')
}

fn (mut app App) key_value_expr(expr KeyValueExpr) {
	if expr.key is Ident {
		app.gen('\t${expr.key.name}: ')
	} else {
		app.expr(expr.key)
		app.gen(': ')
	}
	app.expr(expr.value)
	app.genln('')
}

fn (mut app App) array_type(node ArrayType) {
	if node.elt is Ident {
		app.gen('[]${node.elt.name}')
	} else if node.elt is StarExpr {
		app.gen('[]')
		app.star_expr(node.elt)
		// app.gen('[]&${node.elt.name}')
	}
}

fn (mut app App) star_expr(node StarExpr) {
	app.gen('&')
	app.expr(node.x)
}

fn (mut app App) ident(node Ident) {
	// app.gen('f=${app.force_upper}')
	app.gen(app.go2v_ident(node.name))
}
