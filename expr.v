// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) expr(expr Expr) {
	match expr {
		InvalidExpr {
			eprintln('> invalid expression encountered')
		}
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
		CompositeLit {
			app.composite_lit(expr)
		}
		KeyValueExpr {
			app.key_value_expr(expr)
		}
		IndexExpr {
			app.index_expr(expr)
		}
		MapType {
			app.map_type(expr)
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
		SliceExpr {
			app.slice_expr(expr)
		}
		FuncType {
			app.func_type(expr)
		}
	}
}

fn (mut app App) basic_lit(l BasicLit) {
	if l.kind == 'CHAR' {
		app.gen(quoted_lit(l.value, '`'))
	} else if l.kind == 'STRING' {
		app.gen(quoted_lit(l.value, "'"))
	} else {
		app.gen(l.value)
	}
}

fn quoted_lit(s string, quote string) string {
	mut quote2 := quote
	mut no_quotes := s[1..s.len - 1]
	// Use "" quotes if the string literal contains '
	if quote2 == "'" && no_quotes.contains("'") && !no_quotes.contains('"') {
		// no_quotes = no_quotes.replace(
		quote2 = '"'
	}
	if s.contains('\\"') {
		quote2 = '"'
	}

	return '${quote2}${no_quotes}${quote2}'
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
}

fn (mut app App) array_type(node ArrayType) {
	match node.elt {
		Ident {
			app.gen('[]${go2v_type(node.elt.name)}')
		}
		StarExpr {
			app.gen('[]')
			app.star_expr(node.elt)
			// app.gen('[]&${node.elt.name}')
		}
		SelectorExpr {
			app.gen('[]')
			app.force_upper = true
			app.selector_expr(node.elt)
			app.force_upper = false
		}
		FuncType {
			app.gen('[]')
			app.func_type(node.elt)
		}
		else {
			app.gen('UNKNOWN ELT ${node.elt.type_name()}')
		}
	}
}

fn (mut app App) map_type(node MapType) {
	app.force_upper = true
	app.gen('map[')
	app.expr(node.key)
	app.gen(']')
	app.force_upper = true
	app.expr(node.val)
	app.force_upper = false
}

fn (mut app App) star_expr(node StarExpr) {
	app.gen('&')
	app.expr(node.x)
}

fn (mut app App) slice_expr(node SliceExpr) {
	app.expr(node.x)
	app.gen('[')
	if node.low is InvalidExpr {
	} else {
		app.expr(node.low)
	}
	app.gen('..')
	if node.high is InvalidExpr {
	} else {
		app.expr(node.high)
	}
	app.gen(']')
}

fn (mut app App) ident(node Ident) {
	app.gen(go2v_type(app.go2v_ident(node.name)))
}
