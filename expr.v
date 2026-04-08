// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) expr(expr Expr) {
	match expr {
		InvalidExpr {
			print_backtrace()
			eprintln('> invalid expression encountered')
		}
		ArrayType {
			app.array_type(expr)
		}
		BasicLit {
			app.basic_lit(expr)
		}
		BinaryExpr {
			app.binary_expr(expr)
		}
		CallExpr {
			app.call_expr(expr)
		}
		ChanType {
			app.chan_type(expr)
		}
		CompositeLit {
			app.composite_lit(expr)
		}
		Ellipsis {}
		FuncLit {
			app.func_lit(expr)
		}
		FuncType {
			app.func_type(expr)
		}
		Ident {
			app.ident(expr)
		}
		IndexExpr {
			app.index_expr(expr)
		}
		InterfaceType {
			app.interface_type(expr)
		}
		KeyValueExpr {
			app.key_value_expr(expr)
		}
		MapType {
			app.map_type(expr)
		}
		ParenExpr {
			app.paren_expr(expr)
		}
		SelectorExpr {
			app.selector_expr(expr)
		}
		SliceExpr {
			app.slice_expr(expr)
		}
		StarExpr {
			// In type context (force_upper is true), * means pointer type (&)
			// In expression context, * is dereference operator
			if app.force_upper {
				app.star_expr(expr)
			} else {
				app.star_expr_deref(expr)
			}
		}
		StructType {
			app.struct_type(expr)
		}
		TypeAssertExpr {
			app.type_assert_expr(expr)
		}
		UnaryExpr {
			app.unary_expr(expr)
		}
	}
}

fn (mut app App) array_type(node ArrayType) {
	force_upper := app.force_upper
	app.gen('[')
	if node.len !is InvalidExpr {
		app.expr(node.len)
	}
	app.gen(']')
	app.force_upper = force_upper
	// Skip parentheses when array element is a ParenExpr containing FuncType
	// Go: []func() -> V: []fn() (not [](fn()))
	elt := node.elt
	match elt {
		ParenExpr {
			if elt.x is FuncType {
				app.func_type(elt.x)
				return
			}
		}
		FuncType {
			app.func_type(elt)
			return
		}
		else {}
	}
	app.expr(node.elt)
}

fn (mut app App) basic_lit(l BasicLit) {
	if l.kind == 'CHAR' {
		app.gen(quoted_lit(l.value, '`'))
	} else if l.kind == 'STRING' {
		app.gen(quoted_lit(l.value, "'"))
	} else if l.kind == 'IMAG' {
		// V has no direct `3i` literal syntax; emit a numeric fallback.
		mut numeric := l.value
		if numeric.ends_with('i') {
			numeric = numeric[..numeric.len - 1]
		}
		if numeric.len == 0 || numeric == '+' || numeric == '-' {
			app.gen('0.0')
		} else {
			app.gen(numeric)
		}
	} else {
		app.gen(l.value)
	}
}

fn (mut app App) binary_expr(b BinaryExpr) {
	mut normalized_op := b.op
	if normalized_op.len == 0 || normalized_op.trim_space() == '' {
		normalized_op = '||'
	}
	known_ops := ['+', '-', '*', '/', '%', '==', '!=', '<', '>', '<=', '>=', '&', '|', '^', '&^',
		'<<', '>>', '&&', '||']
	if normalized_op !in known_ops {
		// asty can occasionally emit an empty/non-printable op for logical OR.
		// Falling back to `||` avoids malformed infix expressions such as `a b`.
		normalized_op = '||'
	}
	if normalized_op == '+' && (b.x is BasicLit || b.y is BasicLit) {
		x := b.x
		y := b.y
		if x is BasicLit && x.kind == 'INT' && y is BasicLit && y.kind == 'INT' {
			app.gen('${x.value}${normalized_op}${y.value}')
		} else {
			// Use regular concatenation to properly handle string escaping
			app.expr(x)
			app.gen('+')
			app.expr(y)
		}
	} else if (normalized_op == '==' || normalized_op == '!=') && app.is_error_nil_comparison(b) {
		// Handle error variable comparison with nil: err == nil => err == none
		app.gen_error_nil_comparison(b)
	} else if (normalized_op == '==' || normalized_op == '!=') && app.is_generic_nil_comparison(b) {
		// Prefer isnil(...) for pointer/interface nil checks to avoid unsafe{nil}
		// infix expressions that can trigger vfmt panics on very large outputs.
		app.gen_generic_nil_comparison(b, normalized_op)
	} else if normalized_op in ['<', '>', '<=', '>='] && app.is_potential_enum_comparison(b) {
		// V enums only support == and != directly, not ordering comparisons
		// We need to cast both sides to int, but for enum values (Ident),
		// we need to use the full qualified name (e.g., LogLevel.level_info)
		// We try to infer the enum type from the selector field name
		enum_type := app.infer_enum_type_from_comparison(b)
		app.gen('int(')
		app.gen_enum_expr_with_type(b.x, enum_type)
		app.gen(') ${normalized_op} int(')
		app.gen_enum_expr_with_type(b.y, enum_type)
		app.gen(')')
	} else {
		// Wrap composite literals in parentheses when used in comparisons
		// V parser gets confused by {} in binary expressions
		x_needs_parens := b.x is CompositeLit
		y_needs_parens := b.y is CompositeLit

		if x_needs_parens {
			app.gen('(')
		}
		app.expr(b.x)
		if x_needs_parens {
			app.gen(')')
		}
		if normalized_op == '\u0026^' {
			app.gen(' &~ ')
		} else {
			// Add spaces around operators for clarity and to avoid parsing issues
			// e.g., `}&&` could be misinterpreted
			app.gen(' ${normalized_op} ')
		}
		if y_needs_parens {
			app.gen('(')
		}
		app.expr(b.y)
		if y_needs_parens {
			app.gen(')')
		}
	}
}

fn (app App) is_generic_nil_comparison(b BinaryExpr) bool {
	return (b.x is Ident && b.x.name == 'nil') || (b.y is Ident && b.y.name == 'nil')
}

fn (mut app App) gen_generic_nil_comparison(b BinaryExpr, op string) {
	if b.x is Ident && b.x.name == 'nil' {
		if op == '==' {
			app.gen('isnil(')
			app.expr(b.y)
			app.gen(')')
		} else {
			app.gen('!isnil(')
			app.expr(b.y)
			app.gen(')')
		}
		return
	}
	if op == '==' {
		app.gen('isnil(')
		app.expr(b.x)
		app.gen(')')
	} else {
		app.gen('!isnil(')
		app.expr(b.x)
		app.gen(')')
	}
}

// Check if this is an error variable being compared to nil
fn (app App) is_error_nil_comparison(b BinaryExpr) bool {
	// Check if x is error var and y is nil, or vice versa
	x_is_err := if b.x is Ident { b.x.name.camel_to_snake() in app.error_vars } else { false }
	y_is_nil := if b.y is Ident { b.y.name == 'nil' } else { false }
	if x_is_err && y_is_nil {
		return true
	}
	x_is_nil := if b.x is Ident { b.x.name == 'nil' } else { false }
	y_is_err := if b.y is Ident { b.y.name.camel_to_snake() in app.error_vars } else { false }
	if x_is_nil && y_is_err {
		return true
	}
	return false
}

// Generate error comparison with none instead of unsafe { nil }
fn (mut app App) gen_error_nil_comparison(b BinaryExpr) {
	x_is_nil := if b.x is Ident { b.x.name == 'nil' } else { false }
	if x_is_nil {
		app.gen('none ${b.op} ')
		app.expr(b.y)
	} else {
		app.expr(b.x)
		app.gen(' ${b.op} none')
	}
}

// Common field names that likely contain enum values
const enum_field_names = ['kind', 'type', 'level', 'mode', 'state', 'status', 'op', 'opcode', 'flag',
	'stage', 'log_level']!

// Check if this is an enum comparison that requires int() cast in V
// V enums only support == and != operators, not < > <= >=
fn (app App) is_potential_enum_comparison(b BinaryExpr) bool {
	// Check if x side is a selector accessing an enum-like field
	if b.x is SelectorExpr {
		x_sel := b.x as SelectorExpr
		x_field := x_sel.sel.name.camel_to_snake()
		if x_field in enum_field_names {
			return true
		}
	}
	// Check if y side is a selector accessing an enum-like field
	if b.y is SelectorExpr {
		y_sel := b.y as SelectorExpr
		y_field := y_sel.sel.name.camel_to_snake()
		if y_field in enum_field_names {
			return true
		}
	}
	// Check if either side is an enum value (Ident that's in our enum_values set)
	// Use camel_to_snake to convert Go name to V name for lookup
	if b.x is Ident {
		x_name := (b.x as Ident).name.camel_to_snake()
		if x_name in app.enum_values {
			return true
		}
	}
	if b.y is Ident {
		y_name := (b.y as Ident).name.camel_to_snake()
		if y_name in app.enum_values {
			return true
		}
	}
	return false
}

// infer_enum_type_from_comparison tries to infer the enum type name from a comparison
// by looking at selector expressions. E.g., options.log_level suggests LogLevel type.
fn (app App) infer_enum_type_from_comparison(b BinaryExpr) string {
	// Check if x side is a selector accessing an enum-like field
	if b.x is SelectorExpr {
		x_sel := b.x as SelectorExpr
		field_name := x_sel.sel.name.camel_to_snake()
		// Convert field name to potential enum type name
		// e.g., log_level -> LogLevel
		return field_name.replace('_', ' ').title().replace(' ', '')
	}
	// Check if y side is a selector accessing an enum-like field
	if b.y is SelectorExpr {
		y_sel := b.y as SelectorExpr
		field_name := y_sel.sel.name.camel_to_snake()
		return field_name.replace('_', ' ').title().replace(' ', '')
	}
	return ''
}

// gen_enum_expr_with_type generates an expression for enum comparison
// For Ident enum values, it uses the full qualified name (e.g., LogLevel.level_info)
fn (mut app App) gen_enum_expr_with_type(e Expr, enum_type string) {
	if e is Ident {
		v_name := app.go2v_ident(e.name)
		// If this is an enum value and we have a type name, use qualified name
		if v_name in app.enum_values && enum_type != '' {
			app.gen('${enum_type}.${v_name}')
		} else {
			// Fallback to normal expression
			app.expr(e)
		}
	} else {
		// For other expressions (like selector expr), use normal expr()
		app.expr(e)
	}
}

fn (mut app App) chan_type(node ChanType) {
	app.gen('chan ')
	// In Go, chan struct{} is used for signaling with no data
	// V doesn't support empty struct types, so use bool instead
	if node.value is StructType {
		st := node.value as StructType
		if st.fields.list.len == 0 {
			app.gen('bool')
			return
		}
	}
	// Channel element types are always type names, so use force_upper to get
	// proper translation (e.g., Go `int` -> V `isize`, not `int_`)
	saved_force_upper := app.force_upper
	app.force_upper = true
	app.expr(node.value)
	app.force_upper = saved_force_upper
}

fn (mut app App) ident(node Ident) {
	// Handle iota in const blocks - replace with actual numeric value
	if node.name == 'iota' && app.in_const_block {
		app.gen('${app.current_iota_value}')
		return
	}
	// Check if this variable was renamed due to shadowing (using Go name as key)
	if node.name in app.name_mapping {
		app.gen(go2v_type(app.name_mapping[node.name]))
		return
	}
	v_name := app.go2v_ident(node.name)
	// Add . prefix for enum values in V
	if v_name in app.enum_values {
		app.gen('.')
	}
	app.gen(go2v_type(v_name))
}

fn (mut app App) index_expr(s IndexExpr) {
	app.expr(s.x)
	app.gen('[')
	if s.x is Ident && (s.x as Ident).name in app.map_string_key_vars {
		app.expr(s.index)
		app.gen('.str()')
	}
	// If the index is a struct literal, convert to string for V map compatibility.
	// V doesn't support struct types as map keys, so we use string keys.
	else if s.index is CompositeLit {
		app.expr(s.index)
		app.gen('.str()')
	} else {
		app.expr(s.index)
	}
	app.gen(']')
}

fn (mut app App) key_value_expr(expr KeyValueExpr) {
	if expr.key is Ident {
		app.gen('\t${app.go2v_ident(expr.key.name)}: ')
	} else {
		app.expr(expr.key)
		app.gen(': ')
	}
	app.expr(expr.value)
}

fn (mut app App) map_type(node MapType) {
	app.gen('map[')
	match node.key {
		Ident {
			if node.key.name in app.struct_types {
				// V does not support struct keys in maps; map them to string keys.
				app.gen('string')
			}
			// Preserve alias/type names for non-struct map keys when available.
			else if node.key.name in app.struct_or_alias {
				app.force_upper = true
				app.gen(app.go2v_ident(node.key.name))
				app.force_upper = false
			} else {
				// Map keys must be capitalized in V for struct types
				conversion := go2v_type_checked(node.key.name)
				if conversion.is_basic {
					app.gen(conversion.v_type)
				} else {
					// V doesn't support struct types as map keys
					// Convert to string - the key will need .str() calls at access sites
					app.gen('string')
				}
			}
		}
		SelectorExpr {
			// V doesn't support struct types as map keys (e.g., map[pkg.Type]V)
			// Convert to string - the key will need .str() calls at access sites
			app.gen('string')
		}
		StarExpr {
			// Pointer type as map key, e.g., map[*Node]bool
			// V doesn't support pointer types as map keys
			// Convert to voidptr for pointer-based comparison
			app.gen('voidptr')
		}
		else {}
	}
	app.gen(']')
	saved_force_upper := app.force_upper
	app.force_upper = true
	match node.val {
		ArrayType {
			app.array_type(node.val as ArrayType)
		}
		FuncType {
			app.func_type(node.val as FuncType)
		}
		Ident {
			ident := node.val as Ident
			conversion := go2v_type_checked(ident.name)
			if conversion.is_basic {
				app.gen(conversion.v_type)
			} else {
				app.gen(app.go2v_ident(ident.name))
			}
		}
		InterfaceType {
			app.interface_type(node.val as InterfaceType)
		}
		MapType {
			app.map_type(node.val as MapType)
		}
		SelectorExpr {
			app.selector_expr(node.val as SelectorExpr)
		}
		StarExpr {
			star := node.val as StarExpr
			if star.x is ArrayType {
				app.array_type(star.x as ArrayType)
			} else {
				app.star_expr(star)
			}
		}
		StructType {
			// Empty struct type, e.g., map[K]struct{}
			app.struct_type(node.val as StructType)
		}
	}
	app.force_upper = saved_force_upper
}

fn (mut app App) paren_expr(p ParenExpr) {
	app.gen('(')
	app.expr(p.x)
	app.gen(')')
}

fn quoted_lit(s string, quote string) string {
	mut quote2 := quote
	go_quote := s[0]
	mut no_quotes := s[1..s.len - 1]

	// For rune literals (backticks), V supports escape sequences directly
	// Special case: if the rune IS a backtick, we need to escape it as `\``
	if quote == '`' {
		if no_quotes == '`' {
			return r'`\``'
		}
		return '`${no_quotes}`'
	}

	mut prefix := ''
	if go_quote == `\`` {
		prefix = 'r'
	}

	// Determine which V quote style to use
	if prefix == 'r' {
		// Raw string: check if it contains quotes
		has_single := no_quotes.contains("'")
		has_double := no_quotes.contains('"')

		if has_single && has_double {
			// Contains both quote types - can't use raw string
			// Convert to regular escaped string
			prefix = ''
			quote2 = '"'
			// Escape backslashes first (so we don't double-escape later escapes)
			no_quotes = no_quotes.replace('\\', '\\\\')
			// Escape double quotes
			no_quotes = no_quotes.replace('"', '\\"')
		} else if has_single {
			// V raw strings r'...' can't contain literal ', so use r"..." instead
			quote2 = '"'
		}
		// else: no single quotes, use r'...' (default)
	} else {
		has_single := no_quotes.contains("'")
		has_escaped_double := no_quotes.contains('\\"')
		// Check for escape sequences that require double quotes in V
		// In V, single quotes treat backslash literally, double quotes process escapes
		has_escape_seq := no_quotes.contains('\\n') || no_quotes.contains('\\t')
			|| no_quotes.contains('\\r') || no_quotes.contains('\\x') || no_quotes.contains('\\u')
			|| no_quotes.contains('\\0') || no_quotes.contains('\\a') || no_quotes.contains('\\b')
			|| no_quotes.contains('\\f') || no_quotes.contains('\\v')

		if has_escape_seq {
			// Must use double quotes to process escape sequences
			quote2 = '"'
			// Unescape double quotes since we're now using double quotes
			if has_escaped_double {
				// Keep the escaping since we're using double quotes
			}
		} else if has_single && has_escaped_double {
			// String has both ' and \" - use double quotes and keep escaping
			quote2 = '"'
		} else if has_single {
			// String has ' but no \" - use double quotes
			quote2 = '"'
		} else if has_escaped_double {
			// String has \" but no ' - use single quotes and unescape
			quote2 = "'"
			no_quotes = no_quotes.replace('\\"', '"')
		}
		// else: no special chars, use default single quotes
	}

	// Escape $ and backticks in non-raw strings to prevent V from interpreting
	// ${} as string interpolation or sequences like "2n`" as string prefixes
	if prefix != 'r' {
		no_quotes = no_quotes.replace('$', '\\$')
		no_quotes = no_quotes.replace('`', '\\`')
	}

	return '${prefix}${quote2}${no_quotes}${quote2}'
}

fn (mut app App) selector_expr(s SelectorExpr) {
	// Handle special runtime and os selectors
	if s.x is Ident {
		ident := s.x as Ident
		if ident.name == 'runtime' {
			match s.sel.name {
				'GOOS' {
					// runtime.GOOS -> os.user_os()
					app.gen('os.user_os()')
					return
				}
				'GOARCH' {
					// runtime.GOARCH -> os.uname().machine
					app.gen('os.uname().machine')
					return
				}
				else {}
			}
		} else if ident.name == 'os' {
			// Go's os.Stderr/Stdout/Stdin are variables (*os.File)
			// V's os.stderr/stdout/stdin are functions that return File
			match s.sel.name {
				'Stderr' {
					app.gen('os.stderr()')
					return
				}
				'Stdout' {
					app.gen('os.stdout()')
					return
				}
				'Stdin' {
					app.gen('os.stdin()')
					return
				}
				else {}
			}
		}
	}
	force_upper := app.force_upper // save force upper for `mod.ForceUpper`
	app.force_upper = false
	app.expr(s.x)
	app.gen('.')
	app.force_upper = force_upper
	app.gen(app.go2v_ident(s.sel.name))
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

fn (mut app App) star_expr(node StarExpr) {
	if app.no_star {
		app.no_star = false
	} else {
		app.gen('&')
	}
	app.expr(node.x)
}

// star_expr_deref handles *x in expression context (dereferencing)
fn (mut app App) star_expr_deref(node StarExpr) {
	app.gen('*')
	app.expr(node.x)
}

fn (mut app App) type_assert_expr(t TypeAssertExpr) {
	// TODO more?
	app.expr(t.x)
}

fn (mut app App) unary_expr(u UnaryExpr) {
	if u.op == '^' {
		// In Go bitwise NOT is ^x
		// In V it's ~x, ^ is only used for XOR: x^b
		app.gen('~')
	} else if u.op != '+' {
		app.gen(u.op)
	}
	app.expr(u.x)
}
