module transpiler

// types equivalence (left Go & right V)
const (
	get_type = {
		'bool':    'bool'
		'string':  'string'
		'byte':    'u8'
		'rune':    'rune'
		'int':     'int'
		'int8':    'i8'
		'int16':   'i16'
		'int32':   'i32'
		'int64':   'i64'
		'uint8':   'u8'
		'uint16':  'u16'
		'uint32':  'u32'
		'uint64':  'u64'
		'float32': 'f32'
		'float64': 'f64'
	}
	keywords = ['as', 'asm', 'assert', 'atomic', 'break', 'const', 'continue', 'defer', 'else',
		'embed', 'enum', 'false', 'fn', 'for', 'go', 'goto', 'if', 'import', 'in', 'interface',
		'is', 'lock', 'match', 'module', 'mut', 'none', 'or', 'pub', 'return', 'rlock', 'select',
		'shared', 'sizeof', 'static', 'struct', 'true', 'type', 'typeof', 'union', 'unsafe',
		'volatile', '__offsetof']
)

enum Case {
	ignore
	snake_case
	camel_case
}

// format a given value as needed
fn format_value(str string, case Case) string {
	if str.len > 0 {
		raw := match str[1] {
			`\\` {
				"'" + str#[3..-3].replace('\\\\', '\\').replace("'", "\\'") + "'"
			} // strings
			`'` {
				'`${str#[2..-2].replace('\\\\', '\\')}`'
			} // runes
			else {
				str#[1..-1]
			} // everything else
		}

		is_string := raw[0] == `'` || raw[0] == `\``

		if case == .snake_case && !is_string {
			mut out := []rune{}
			mut prev_ch := ` `

			for i, ch in raw {
				if `A` <= ch && ch <= `Z` && i != 0 && !(`A` <= prev_ch && prev_ch <= `Z`) {
					out << `_`
				}

				if `A` <= ch && ch <= `Z` {
					out << ch + 32
				} else if ch != `_` || !(`A` <= prev_ch && prev_ch <= `Z`) {
					out << ch
				}

				prev_ch = ch
			}

			return out.string()
		} else if case == .camel_case && !is_string {
			sub := if `A` <= raw[0] && raw[0] <= `Z` { 0 } else { 32 }

			return (raw[0] - u8(sub)).ascii_str() + raw[1..]
		} else {
			return raw
		}
	} else {
		return str
	}
}

// get the type of property/function arguments etc.
fn (mut v VAST) get_type(tree Tree) string {
	mut temp := tree.child['Type'].tree
	mut type_prefix := ''
	mut @type := ''
	mut next_is_end := if 'X' in temp.child { false } else { true }

	for ('X' in temp.child) || next_is_end {
		// pointers
		if temp.name == '*ast.StarExpr' {
			type_prefix += '&'
		}
		// TODO: rework that
		if 'X' in temp.child {
			temp = temp.child['X'].tree
		}

		// arrays
		if temp.name == '*ast.ArrayType' {
			type_prefix += '[]'
			temp = temp.child['Elt'].tree
		}

		// pointers
		if temp.name == '*ast.StarExpr' {
			type_prefix += '&'
		}

		// maps
		if temp.name == '*ast.MapType' {
			@type += 'map[' + v.get_name(temp.child['Key'].tree, .ignore, false) + ']' +
				v.get_name(temp.child['Value'].tree, .ignore, false)
		}

		// functions
		if temp.name == '*ast.FuncType' {
			@type += v.stmt_to_string(v.get_function(temp.parent))
		}

		@type += v.get_name(temp, .ignore, false)

		v.get_embedded(temp)

		temp = temp.child['X'].tree

		if next_is_end {
			break
		}
		if !('X' in temp.child['X'].tree.child || 'Sel' in temp.child) {
			next_is_end = true
		}
	}

	return type_prefix + if @type in transpiler.get_type {
		// transform Go types into V ones
		transpiler.get_type[@type]
	} else {
		@type
	}
}

// TODO: make it work for things like `a[i]`
// TODO: comment this and find a better name
fn (mut v VAST) get_name(tree Tree, case Case, from_declaration bool) string {
	raw_name := v.get_initial_name(tree, .ignore)
	formatted_name := v.get_initial_name(tree, case)
	already_declared := v.declared_vars_old.contains(raw_name)

	if from_declaration {
		println('from declaration')
		// suffix the name with an int and increment it until it's unique
		mut suffix := 1
		mut new_name := formatted_name

		if v.declared_vars_new.contains(new_name) {
			for (v.declared_vars_new.contains(new_name)) {
				new_name = '${formatted_name}_${int(suffix)}'
				suffix++
			}
		}

		v.declared_vars_old << raw_name
		v.declared_vars_new << new_name

		return new_name
	} else {
		if already_declared {
			println('already declared: $raw_name')
			println(v.declared_vars_old)
			println(v.declared_vars_new)
			return v.declared_vars_new[v.declared_vars_old.index(raw_name)]
		}
		return formatted_name
	}
}

// get the name of a variable/property/function etc.
fn (mut v VAST) get_initial_name(tree Tree, case Case) string {
	mut temp := tree
	mut namespaces := []string{}
	// All `next_is_end` related code is a trick to repeat one more time the loop
	mut next_is_end := if 'X' in temp.child { false } else { true }

	for ('X' in temp.child) || next_is_end {
		// `a.b.c` syntax
		if 'Sel' in temp.child {
			raw_value := temp.child['Sel'].tree.child['Name'].val
			formatted_value := format_value(raw_value, case)
			// excape reserved keywords
			// reserved keywords are already formatted
			// that's why checking if the unformatted value is the same as the formatted one is great test
			if raw_value#[1..-1] != formatted_value && transpiler.keywords.contains(formatted_value) {
				namespaces << '.@$formatted_value'
			} else {
				namespaces << '.$formatted_value'
			}
		}

		// name
		if 'Name' in temp.child {
			if 'Name' in temp.child['Name'].tree.child {
				temp = temp.child['Name'].tree
			}
			raw_value := temp.child['Name'].val
			formatted_value := format_value(raw_value, case)
			// excape reserved keywords
			// reserved keywords are already formatted
			// that's why checking if the unformatted value is the same as the formatted one is great test
			if raw_value#[1..-1] != formatted_value && transpiler.keywords.contains(formatted_value) {
				namespaces << '@$formatted_value'
			} else {
				namespaces << formatted_value
			}
		}

		// value
		if 'Value' in temp.child {
			namespaces << format_value(temp.child['Value'].val, case)

			v.get_embedded(temp)
		}

		// `a[idx]` syntax
		if 'Index' in temp.child {
			namespaces << '[' + v.stmt_to_string(v.get_stmt(temp.child['Index'].tree)) + ']'
		}

		temp = temp.child['X'].tree
		if next_is_end {
			break
		}
		if 'X' !in temp.child {
			next_is_end = true
		}
	}

	// transform Go types into V ones for type casting
	if namespaces.len == 1 && namespaces[0] in transpiler.get_type {
		namespaces[0] = transpiler.get_type[namespaces[0]]
	}

	mut out := ''

	for i := namespaces.len - 1; i >= 0; i-- {
		out += namespaces[i]
	}

	return out
}

// check if the tree contains an embedded declaration and extract it if so
fn (mut v VAST) get_embedded(tree Tree) {
	if 'Obj' in tree.child {
		v.extract_declaration(tree.child['Obj'].tree, true)
	}
}

// get the condition string from a tree for if/for/match statements
fn (mut v VAST) get_raw_operation(tree Tree) string {
	// logic part
	if 'Name' !in tree.child {
		// left-hand
		x := if tree.child['X'].tree.name == '*ast.ParenExpr'
			|| tree.child['X'].tree.name == '*ast.BinaryExpr' {
			v.get_raw_operation(tree.child['X'].tree)
		} else if 'X' in tree.child {
			v.stmt_to_string(v.get_stmt(tree.child['X'].tree))
		} else {
			''
		}

		// operator
		cond := tree.child['Op'].val

		// right-hand
		y := if tree.child['Y'].tree.name == '*ast.ParenExpr'
			|| tree.child['Y'].tree.name == '*ast.BinaryExpr' {
			v.get_raw_operation(tree.child['Y'].tree)
		} else if 'Y' in tree.child {
			v.stmt_to_string(v.get_stmt(tree.child['Y'].tree))
		} else {
			''
		}

		// parentheses
		if cond == '&&' || cond == '||' {
			return '($x $cond $y)'
		} else if cond.len + x.len + y.len == 0 {
			stmt := v.get_stmt(tree)
			return if stmt is NotYetImplStmt { ' ' } else { v.stmt_to_string(stmt) }
		} else if y.len == 0 {
			return '$cond $x'
		} else {
			return '$x $cond $y'
		}
	} else {
		// value part
		return v.get_name(tree, .ignore, false)
	}
}

// format the condition string obtained from get_raw_operation
fn (mut v VAST) get_operation(tree Tree) string {
	mut cond := v.get_raw_operation(tree)

	mut out := []rune{}
	mut space_count := 0

	for i, ch in cond {
		space_count = if ch == ` ` { space_count + 1 } else { 0 }
		// remove useless spaces and parentheses
		if !(space_count > 1 || (i == 0 && ch == `(`) || (i == cond.len - 1 && ch == `)`)) {
			out << ch
		}
	}

	return out.string()
}

// get the variable statement (VariableStmt) from a tree
fn (mut v VAST) get_var(tree Tree, short bool) VariableStmt {
	left_hand := if short { tree.child['Lhs'].tree.child } else { tree.child['Names'].tree.child }
	right_hand := if short { tree.child['Rhs'].tree.child } else { tree.child['Values'].tree.child }

	mut var_stmt := VariableStmt{
		middle: tree.child['Tok'].val
		@type: v.get_type(tree)
	}

	for _, name in left_hand {
		var_stmt.names << v.get_name(name.tree, .snake_case, true)
	}
	for _, val in right_hand {
		var_stmt.values << v.get_stmt(val.tree)
	}

	return var_stmt
}

// get the increment statement (IncDecStmt) from a tree
fn (mut v VAST) get_inc_dec(tree Tree) IncDecStmt {
	return IncDecStmt{
		var: v.get_name(tree, .ignore, false)
		inc: tree.child['Tok'].val
	}
}

// get the body of a function/if/for/match statement etc.
// basically everything that contains a block of code
fn (mut v VAST) get_body(tree Tree) []Statement {
	mut body := []Statement{}
	// all the variables declared after this limit will go out of scope at the end of the function
	limit := v.declared_vars_old.len

	// go through every statement
	for _, stmt in tree.child['List'].tree.child {
		body << v.get_stmt(stmt.tree)
	}
	// TODO: remove this
	dump(v.declared_vars_old)
	dump(v.declared_vars_new)
	v.declared_vars_old = v.declared_vars_old[..limit]
	v.declared_vars_new = v.declared_vars_new[..limit]

	return body
}

// extract a single statement
fn (mut v VAST) get_stmt(tree Tree) Statement {
	mut ret := Statement(NotYetImplStmt{})

	match tree.name {
		// `var` syntax
		'*ast.DeclStmt' {
			mut var_stmt := v.get_var(tree.child['Decl'].tree.child['Specs'].tree.child['0'].tree,
				false)
			var_stmt.middle = ':='

			ret = var_stmt
		}
		// `:=`, `+=` etc. syntax
		'*ast.AssignStmt' {
			ret = v.get_var(tree, true)
		}
		// basic value
		'*ast.BasicLit' {
			ret = BasicValueStmt{v.get_name(tree, .ignore, false)}
		}
		// variable, function call, etc.
		'*ast.Ident', '*ast.IndexExpr', '*ast.SelectorExpr' {
			ret = BasicValueStmt{v.get_name(tree, .snake_case, false)}
			v.get_embedded(tree)
		}
		'*ast.MapType' {
			ret = MapStmt{
				key_type: v.get_name(tree.child['Key'].tree, .ignore, false)
				value_type: v.get_name(tree.child['Value'].tree, .ignore, false)
			}
		}
		'*ast.ArrayType' {
			ret = ArrayStmt{
				@type: v.get_name(tree.child['Elt'].tree, .ignore, false)
			}
		}
		// (almost) basic variable value
		// eg: -1
		'*ast.UnaryExpr' {
			op := if tree.child['Op'].val != 'range' { tree.child['Op'].val } else { '' }
			ret = ComplexValueStmt{
				op: op
				value: v.get_stmt(tree.child['X'].tree)
			}
		}
		// arrays & `Struct{}` syntaxt
		'*ast.CompositeLit' {
			base := tree.child['Type'].tree

			match base.name {
				// arrays
				'*ast.ArrayType' {
					mut array := ArrayStmt{
						@type: v.get_type(tree)[2..] // remove `[]`
						len: v.get_name(base.child['Len'].tree, .ignore, false)
					}
					for _, el in tree.child['Elts'].tree.child {
						array.values << v.get_stmt(el.tree)
					}
					ret = array
				}
				// structs
				'*ast.Ident', '', '*ast.SelectorExpr' {
					mut @struct := StructStmt{
						name: if base.name == '' {
							v.current_implicit_map_type
						} else {
							v.get_name(base, .ignore, false)
						}
					}

					for _, el in tree.child['Elts'].tree.child {
						@struct.fields << v.get_stmt(el.tree)
					}

					v.get_embedded(base)

					ret = @struct
				}
				// maps
				'*ast.MapType' {
					// short `{"key": "value"}` syntax
					v.current_implicit_map_type = v.get_name(base.child['Value'].tree,
						.ignore, false)
					no_type := v.current_implicit_map_type.len == 0

					mut map_stmt := MapStmt{
						key_type: v.get_name(base.child['Key'].tree, .ignore, false)
						value_type: v.current_implicit_map_type
					}

					for _, el in tree.child['Elts'].tree.child {
						raw := v.get_stmt(el.tree)

						if no_type {
							// direct values
							mut key_val_stmt := raw as KeyValStmt
							mut array := ArrayStmt{}

							for field in (key_val_stmt.value as StructStmt).fields {
								array.values << field
							}

							key_val_stmt.value = array
							map_stmt.values << key_val_stmt
						} else {
							// normal
							map_stmt.values << raw
						}
					}

					v.get_embedded(base)

					ret = map_stmt
				}
				else {
					ret = not_implemented(tree)
				}
			}
		}
		// `key: value` syntax
		'*ast.KeyValueExpr' {
			ret = KeyValStmt{
				key: v.get_name(tree.child['Key'].tree, .snake_case, false)
				value: v.get_stmt(tree.child['Value'].tree)
			}
		}
		// slices (slicing)
		'*ast.SliceExpr' {
			mut slice_stmt := SliceStmt{
				value: v.get_name(tree.child['X'].tree, .ignore, false)
				low: BasicValueStmt{}
				high: BasicValueStmt{}
			}
			if 'Low' in tree.child {
				slice_stmt.low = v.get_stmt(tree.child['Low'].tree)
			}
			if 'High' in tree.child {
				slice_stmt.high = v.get_stmt(tree.child['High'].tree)
			}
			ret = slice_stmt
		}
		// (nested) function/method call
		'*ast.ExprStmt', '*ast.CallExpr' {
			base := if tree.name == '*ast.ExprStmt' { tree.child['X'].tree } else { tree }

			mut call_stmt := CallStmt{
				namespaces: v.get_name(base.child['Fun'].tree, .snake_case, false)
			}

			// function/method arguments
			for _, arg in base.child['Args'].tree.child {
				call_stmt.args << v.get_stmt(arg.tree)
			}

			v.get_embedded(base.child['Fun'].tree)

			ret = call_stmt
		}
		// `i++` & `i--`
		'*ast.IncDecStmt' {
			ret = v.get_inc_dec(tree)
		}
		// if/else
		'*ast.IfStmt' {
			mut if_stmt := IfStmt{}
			mut temp := tree
			mut next_is_end := if 'Else' in temp.child { false } else { true }

			for ('Else' in temp.child || next_is_end) {
				mut if_else := IfElse{}

				// `if z := 0; z < 10` syntax
				var := v.get_var(temp.child['Init'].tree, true)
				if var.names.len > 0 {
					if_else.body << var
					// TODO: support https://go.dev/tour/flowcontrol/7
				}

				// condition
				if_else.condition = v.get_operation(temp.child['Cond'].tree)
				if var.names.len != 0 {
					if var.values[0] is BasicValueStmt {
						if_else.condition = if_else.condition.replace(var.names[0], (var.values[0] as BasicValueStmt).value)
					}
					// TODO: create a system to support other types of statement
				}

				// body
				if_else.body << if 'Body' in temp.child {
					// `if` or `else if` branchs
					v.get_body(temp.child['Body'].tree)
				} else {
					// `else` branchs
					v.get_body(temp)
				}

				if_stmt.branchs << if_else

				if next_is_end {
					break
				}
				if 'Else' !in temp.child['Else'].tree.child {
					next_is_end = true
				}
				temp = temp.child['Else'].tree
			}

			ret = if_stmt
		}
		// condition for/bare for/C-style for
		'*ast.ForStmt' {
			mut for_stmt := ForStmt{}

			// init
			for_stmt.init = v.get_var(tree.child['Init'].tree, true)
			for_stmt.init.mutable = false

			// condition
			for_stmt.condition = v.get_operation(tree.child['Cond'].tree)

			// post
			post_base := tree.child['Post'].tree
			if post_base.child.len > 0 {
				for_stmt.post = v.get_stmt(post_base)
			}

			// body
			for_stmt.body = v.get_body(tree.child['Body'].tree)

			ret = for_stmt
		}
		// break/continue
		'*ast.BranchStmt' {
			ret = BranchStmt{tree.child['Tok'].val}
		}
		// for in
		'*ast.RangeStmt' {
			mut forin_stmt := ForInStmt{}

			// classic syntax
			if tree.child['Tok'].val != 'ILLEGAL' {
				// idx
				forin_stmt.idx = tree.child['Key'].tree.child['Name'].val#[1..-1]

				// element & variable
				temp_var := v.get_var(tree.child['Key'].tree.child['Obj'].tree.child['Decl'].tree,
					true)
				forin_stmt.element = temp_var.names[1] or { '_' }
				forin_stmt.variable = temp_var.values[0] or { BasicValueStmt{'_'} }
			} else {
				// `for range variable {` syntax
				forin_stmt.variable = BasicValueStmt{v.get_name(tree, .ignore, false)}
			}

			// body
			forin_stmt.body = v.get_body(tree.child['Body'].tree)

			ret = forin_stmt
		}
		'*ast.ReturnStmt' {
			mut return_stmt := ReturnStmt{}

			for _, el in tree.child['Results'].tree.child {
				return_stmt.values << v.get_stmt(el.tree)
			}

			ret = return_stmt
		}
		'*ast.DeferStmt' {
			ret = DeferStmt{v.get_stmt(tree.child['Call'].tree)}
		}
		'*ast.SwitchStmt' {
			mut match_stmt := MatchStmt{
				value: v.get_stmt(tree.child['Tag'].tree)
			}

			// `switch z := 0; z < 10` syntax
			var := v.get_var(tree.child['Init'].tree, true)
			if var.names.len > 0 {
				// TODO: have a system to prefix the variable name & a system to change all it's occurences in the match statement cases
				match_stmt.init = var
			}

			// cases
			for _, case in tree.child['Body'].tree.child['List'].tree.child {
				mut match_case := MatchCase{
					values: v.get_body(case.tree)
				}

				for _, case_stmt in case.tree.child['Body'].tree.child {
					match_case.body << v.get_stmt(case_stmt.tree)
				}

				match_stmt.cases << match_case
			}

			// add an else statement if not already present
			if match_stmt.cases.last().values.len != 0 {
				match_stmt.cases << MatchCase{}
			}

			ret = match_stmt
		}
		'*ast.BinaryExpr' {
			ret = BasicValueStmt{v.get_operation(tree)}
		}
		'*ast.FuncLit' {
			ret = v.get_function(tree)
		}
		else {
			ret = not_implemented(tree)
		}
	}

	return v.style_stmt(ret)
}

fn not_implemented(tree Tree) NotYetImplStmt {
	mut hint := ''

	if 'TokPos' in tree.child {
		hint = 'at character ${tree.child['TokPos'].val}'
	} else if 'NamePos' in tree.child {
		hint = 'at character ${tree.child['NamePos'].val}'
	} else if 'OpPos' in tree.child {
		hint = 'at character ${tree.child['OpPos'].val}'
	} else if 'Lbrace' in tree.child {
		hint = 'from character ${tree.child['Lbrace'].val} to character ${tree.child['Rbrace'].val}'
	} else if 'Lparen' in tree.child {
		hint = 'from character ${tree.child['Lparen'].val} to character ${tree.child['Rparen'].val}'
	} else {
		hint = 'at unknown character'
	}

	if hint == 'at unknown character' && 'Tok' in tree.child {
		return not_implemented(tree.child['X'].tree)
	} else if tree.name.len > 0 {
		eprintln('Go feature `$tree.name` $hint not currently implemented.\nPlease report the missing feature at https://github.com/vlang/go2v/issues/new')
	}

	return NotYetImplStmt{}
}
