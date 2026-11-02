module main

import json2

fn test_recursive_expression_json_decoding() ! {
	expr := json2.decode[Expr]('{"_type":"BinaryExpr","X":{"_type":"Ident","Name":"x"},"Op":"+","Y":{"_type":"BasicLit","Kind":"INT","Value":"1"}}')!
	assert expr is BinaryExpr
	if expr is BinaryExpr {
		assert expr.op == '+'
		assert expr.x is Ident
		assert expr.y is BasicLit
	}
}
