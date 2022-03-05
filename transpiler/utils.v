module transpiler

// types equivalence (left Go & right V)
const (
	get_type = {
		'bool':    'bool'
		'string':  'string'
		'byte':    'byte'
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
	go_types = get_type.keys()
)

// TODO: cleanup utils functions like get_value, get_type, get_name, get_namespace, etc.
// They can probably be merged

// get the value of a variable etc. Basically, everything that can be of multiple types
fn (mut v VAST) get_value(tree Tree) string {
	// get the raw value
	mut val := if 'Value' in tree.child {
		// almost everything
		tree.child['Value'].val
	} else if 'Name' in tree.child {
		// bools, iotas (enums), variables
		tree.child['Name'].val
	} else {
		''
	}

	// format the value
	if val.len != 0 {
		val = match val[1] {
			`\\` { "'" + val#[3..-3].replace('\\\\', '\\').replace("'", "\\'") + "'" } // strings
			`'` { '`${val#[2..-2]}`' } // runes
			else { val#[1..-1] } // everything else
		}

		// structs (structs always starts with a capital letter and variable names never)
		if `A` <= val[0] && val[0] <= `Z` {
			val += '{}'
		}
	}

	v.get_embedded(tree)

	return val
}

// get the name of a variable/property/function etc.
fn (mut v VAST) get_name(tree Tree, deep bool, snake_case bool) string {
	raw_name := if deep {
		tree.child['Name'].tree.child['Name'].val#[1..-1]
	} else {
		tree.child['Name'].val#[1..-1]
	}

	if snake_case {
		// convert to snake case
		mut out := []rune{}

		for i, ch in raw_name {
			if `A` <= ch && ch <= `Z` {
				if i != 0 {
					out << `_`
				}
				out << ch + 32
			} else {
				out << ch
			}
		}

		return out.string()
	} else {
		// capitalize
		sub := if `A` <= raw_name[0] && raw_name[0] <= `Z` { 0 } else { 32 }

		return (raw_name[0] - byte(sub)).ascii_str() + raw_name[1..]
	}
}

// get the type of property/function arguments etc.
fn (mut v VAST) get_type(tree Tree, deep bool) string {
	mut @type := ''
	mut temp := if deep { tree.child['Type'].tree } else { tree }

	// arrays
	if temp.name == '*ast.ArrayType' {
		@type = '[]'
		temp = temp.child['Elt'].tree
	}

	v.get_embedded(temp)

	return @type + temp.child['Name'].val#[1..-1]
}

// get the namespaces of the left-hand side of an assignment or a function call
// in `a.b.c(...)` `a`, `b` and `c` are namespaces
fn (mut v VAST) get_namespaces(tree Tree) string {
	mut temp := tree
	mut namespaces := []string{}
	// All `near_end` related code is a trick to repeat one more time the loop
	mut near_end := if 'X' in temp.child { false } else { true }

	for (('X' in temp.child) || near_end) {
		// value
		if 'Value' in temp.child {
			namespaces << v.get_value(temp)
		}

		// `a` syntax
		if 'Name' in temp.child {
			namespaces << v.get_name(temp, false, true)
		}

		// `a.b.c` syntax
		if 'Sel' in temp.child {
			namespaces << '.' + v.get_name(temp.child['Sel'].tree, false, true)
		}

		// `a[idx]` syntax
		if 'Index' in temp.child {
			namespaces << '[' + v.get_namespaces(temp.child['Index'].tree) + ']'
		}

		temp = temp.child['X'].tree

		if near_end {
			break
		}
		if !('X' in temp.child['X'].tree.child || 'Sel' in temp.child) {
			near_end = true
		}
	}

	if namespaces.len == 1 && namespaces[0] in transpiler.go_types {
		namespaces[0] = transpiler.get_type[namespaces[0]]
	}

	mut out := ''

	for i := namespaces.len - 1; i >= 0; i-- {
		out += namespaces[i]
	}

	return out
}

// check if the tree contains an embedded declaration, and extract it if so
fn (mut v VAST) get_embedded(tree Tree) {
	if 'Obj' in tree.child {
		v.extract_declaration(tree.child['Obj'].tree, true)
	}
}

// get the condition string from a tree for if/for/match statements
fn (mut v VAST) get_raw_condition(tree Tree) string {
	if 'Name' !in tree.child {
		x := if 'X' in tree.child['X'].tree.child {
			v.get_raw_condition(tree.child['X'].tree)
		} else {
			v.get_value(tree.child['X'].tree)
		}

		cond := tree.child['Op'].val

		y := if 'Y' in tree.child['Y'].tree.child {
			v.get_raw_condition(tree.child['Y'].tree)
		} else {
			v.get_value(tree.child['Y'].tree)
		}

		if cond == '&&' || cond == '||' {
			return '($x $cond $y)'
		} else {
			return '$x $cond $y'
		}
	} else {
		return v.get_value(tree)
	}
}

// format the condition string obtained from get_raw_condition
fn (mut v VAST) get_condition(tree Tree) string {
	mut cond := v.get_raw_condition(tree)

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
fn (mut v VAST) get_var(tree Tree) VariableStmt {
	mut names := []string{}
	mut values := []Statement{}

	for _, name in tree.child['Lhs'].tree.child {
		names << v.get_namespaces(name.tree)
	}
	for _, val in tree.child['Rhs'].tree.child {
		values << v.get_stmt(val.tree)
	}

	return VariableStmt{
		names: names
		middle: tree.child['Tok'].val
		values: values
	}
}

// get the increment statement (IncDecStmt) from a tree
fn (mut v VAST) get_inc_dec(tree Tree) IncDecStmt {
	return IncDecStmt{
		var: v.get_namespaces(tree)
		inc: tree.child['Tok'].val
	}
}

// get the body of a function/if/for/match statement etc. Basically everything that contains a block of code
fn (mut v VAST) get_body(tree Tree) []Statement {
	mut body := []Statement{}

	// go through every statement
	for _, stmt in tree.child['List'].tree.child {
		body << v.get_stmt(stmt.tree)
	}

	return v.v_style(body)
}

fn (mut v VAST) get_stmt(tree Tree) Statement {
	match tree.name {
		// `var` syntax
		'*ast.DeclStmt' {
			// TODO: remake that to reuse the get_var function
			base := tree.child['Decl'].tree.child['Specs'].tree.child['0'].tree

			mut names := []string{}
			mut values := []Statement{}

			for _, var in base.child['Names'].tree.child {
				names << v.get_name(var.tree, false, true)
			}
			for _, var in base.child['Values'].tree.child {
				values << v.get_stmt(var.tree)
			}

			return VariableStmt{
				names: names
				middle: ':='
				values: values
				@type: transpiler.get_type[v.get_name(base.child['Type'].tree, false,
					true)]
			}
		}
		// `:=` & `=` syntax
		'*ast.AssignStmt' {
			return v.get_var(tree)
		}
		// basic value
		'*ast.BasicLit', '*ast.Ident', '*ast.SelectorExpr' {
			return BasicValueStmt{v.get_namespaces(tree)}
		}
		// (almost) basic variable value
		// eg: -1
		'*ast.UnaryExpr' {
			op := if tree.child['Op'].val != 'range' { tree.child['Op'].val } else { '' }
			return BasicValueStmt{op + v.get_value(tree.child['X'].tree)}
		}
		// arrays & `Struct{}` syntaxt
		'*ast.CompositeLit' {
			base := tree.child['Type'].tree

			match base.name {
				// arrays
				'*ast.ArrayType' {
					mut array := ArrayStmt{
						@type: v.get_type(tree, true)[2..] // remove `[]`
						len: v.get_value(base.child['Len'].tree)
					}
					for _, el in tree.child['Elts'].tree.child {
						if v.get_value(el.tree.child['Type'].tree).len > 0 {
							array.values << v.get_value(el.tree.child['Type'].tree)
						} else {
							array.values << v.get_value(el.tree)
						}
					}
					return array
				}
				// structs
				'*ast.Ident', '' {
					mut @struct := StructStmt{
						name: if base.name == '' {
							v.current_implicit_map_type
						} else {
							v.get_name(base, false, false)
						}
					}

					for _, el in tree.child['Elts'].tree.child {
						@struct.fields << v.get_stmt(el.tree)
					}

					v.get_embedded(base)

					return @struct
				}
				// maps
				'*ast.MapType' {
					// short `{"key": "value"}` syntax
					v.current_implicit_map_type = v.get_type(base.child['Value'].tree,
						false)

					// TODO: rename to `map` once https://github.com/vlang/v/issues/13663 gets fixed
					mut map_stmt := MapStmt{
						key_type: v.get_type(base.child['Key'].tree, false)
						value_type: v.current_implicit_map_type
					}

					for _, el in tree.child['Elts'].tree.child {
						map_stmt.values << v.get_stmt(el.tree)
					}

					v.get_embedded(base)

					return map_stmt
				}
				else {
					return not_implemented('*ast.CompositeLit/$base.name')
				}
			}
		}
		// `key: value` syntax
		'*ast.KeyValueExpr' {
			return KeyValStmt{
				key: v.get_namespaces(tree.child['Key'].tree)
				value: v.get_stmt(tree.child['Value'].tree)
			}
		}
		// slices (slicing)
		'*ast.SliceExpr' {
			return SliceStmt{
				value: v.get_namespaces(tree.child['X'].tree)
				low: v.get_value(tree.child['Low'].tree)
				high: v.get_value(tree.child['High'].tree)
			}
		}
		// (nested) function/method call
		'*ast.ExprStmt', '*ast.CallExpr' {
			base := if tree.name == '*ast.ExprStmt' { tree.child['X'].tree } else { tree }

			mut clall_stmt := CallStmt{
				namespaces: v.get_namespaces(base.child['Fun'].tree)
			}

			// function/method arguments
			for _, arg in base.child['Args'].tree.child {
				clall_stmt.args << v.get_stmt(arg.tree)
			}
			clall_stmt.args = v.v_style(clall_stmt.args)

			v.get_embedded(base.child['Fun'].tree)

			return clall_stmt
		}
		// `i++` & `i--`
		'*ast.IncDecStmt' {
			return v.get_inc_dec(tree)
		}
		// if/else
		'*ast.IfStmt' {
			mut if_stmt := IfStmt{}
			mut temp := tree
			mut near_end := if 'Else' in temp.child { false } else { true }

			for ('Else' in temp.child || near_end) {
				mut if_else := IfElse{}

				// `if z := 0; z < 10` syntax
				var := v.get_var(temp.child['Init'].tree)
				if var.names.len > 0 {
					if_else.body << var
					// TODO: support https://go.dev/tour/flowcontrol/7
				}

				// condition
				if_else.condition = v.get_condition(temp.child['Cond'].tree)
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

				if near_end {
					break
				}
				if 'Else' !in temp.child['Else'].tree.child {
					near_end = true
				}
				temp = temp.child['Else'].tree
			}

			return if_stmt
		}
		// condition for/bare for/C-style for
		'*ast.ForStmt' {
			mut for_stmt := ForStmt{}

			// init
			for_stmt.init = v.get_var(tree.child['Init'].tree)
			for_stmt.init.mutable = false

			// condition
			for_stmt.condition = v.get_condition(tree.child['Cond'].tree)

			// post
			post_base := tree.child['Post'].tree
			if post_base.child.len > 0 {
				for_stmt.post = v.get_stmt(post_base)
			}

			// body
			for_stmt.body = v.get_body(tree.child['Body'].tree)

			return for_stmt
		}
		// break/continue
		'*ast.BranchStmt' {
			return BranchStmt{tree.child['Tok'].val}
		}
		// for in
		'*ast.RangeStmt' {
			mut forin_stmt := ForInStmt{}

			// classic syntax
			if tree.child['Tok'].val != 'ILLEGAL' {
				// idx
				forin_stmt.idx = tree.child['Key'].tree.child['Name'].val#[1..-1]

				// element & variable
				temp_var := v.get_var(tree.child['Key'].tree.child['Obj'].tree.child['Decl'].tree)
				forin_stmt.element = temp_var.names[1] or { '_' }
				forin_stmt.variable = temp_var.values[0] or { BasicValueStmt{'_'} }
			} else {
				// `for range variable {` syntax
				forin_stmt.variable = BasicValueStmt{v.get_namespaces(tree)}
			}

			// body
			forin_stmt.body = v.get_body(tree.child['Body'].tree)

			return forin_stmt
		}
		'*ast.ReturnStmt' {
			mut return_stmt := ReturnStmt{}

			for _, el in tree.child['Results'].tree.child {
				return_stmt.values << v.get_stmt(el.tree)
			}

			return return_stmt
		}
		'*ast.DeferStmt' {
			return DeferStmt{v.get_stmt(tree.child['Call'].tree)}
		}
		'*ast.IndexExpr' {
			return IndexStmt{
				value: v.get_namespaces(tree)
			}
		}
		'*ast.SwitchStmt' {
			mut match_stmt := MatchStmt{
				value: v.get_stmt(tree.child['Tag'].tree)
			}

			// `switch z := 0; z < 10` syntax
			var := v.get_var(tree.child['Init'].tree)
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
					match_case.body = v.v_style(match_case.body)
				}

				match_stmt.cases << match_case
			}

			return match_stmt
		}
		else {}
	}

	return not_implemented(tree.name)
}

fn not_implemented(feature string) Statement {
	eprintln("A feature in your Go code named `$feature` isn't currently implemented in Go2V, please check the resulting V code and report the missing feature at https://github.com/vlang/go2v/issues/new")
	return NotImplYetStmt{}
}
