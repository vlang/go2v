module transpiler

// `'abc'` will be interpreted as a `string` by default
// `true` will be interpreted as a `bool` by default
// `12` will not be interpreted as a `u32` by default
// any other type than those ones may require casting
const (
	well_interpreted_types = ['bool', 'string', 'rune', 'int']
)

// entry point for the AST extraction phase
fn ast_extractor(tree Tree) VAST {
	mut v_ast := VAST{}

	// TODO: handle comments
	v_ast.extract_module(tree)

	// go through each declaration node & extract the corresponding declaration
	for _, decl in tree.child['Decls'].tree.child {
		v_ast.extract_declaration(decl.tree, false)
	}

	return v_ast
}

// TODO: better system, this one is clumsy
fn (mut v VAST) extract_declaration(tree Tree, embedded bool) {
	base, fn_base, type_of_gen_decl_field_name := if !embedded {
		tree.child['Specs'].tree, tree, 'Tok'
	} else {
		tree, tree.child['Decl'].tree, 'Kind'
	}

	if fn_base.name == '*ast.FuncDecl' {
		v.functions << v.extract_function(fn_base, true)
	} else {
		gen_decl_type := tree.child[type_of_gen_decl_field_name].val
		// enums are a special case
		mut enum_stmt := NameFields{}

		for _, decl in base.child {
			match gen_decl_type {
				'import' {
					v.extract_import(decl.tree)
				}
				'type' {
					ast_type := decl.tree.child['Type'].tree.name
					match ast_type {
						'*ast.StructType' {
							v.extract_struct(decl.tree, false)
						}
						'*ast.InterfaceType' {
							// TODO: support interfaces
						}
						else {
							if ast_type.len > 0 {
								v.extract_sumtype(decl.tree)
							}
						}
					}
				}
				'const', 'var' {
					enum_stmt = v.extract_const_or_enum(decl.tree, enum_stmt, enum_stmt.name.len > 0)
				}
				else {}
			}
		}

		if enum_stmt.name.len > 0 {
			v.enums << enum_stmt
		}
	}
}

// check if the `Tree` contains an embedded declaration and extract it if so
fn (mut v VAST) extract_embedded_declaration(tree Tree) {
	if 'Obj' in tree.child {
		v.extract_declaration(tree.child['Obj'].tree, true)
	}
}

// extract the module name from a `Tree`
fn (mut v VAST) extract_module(tree Tree) {
	v.@module = v.get_name(tree, .snake_case, .other)
}

// extract the imports from a `Tree`
fn (mut v VAST) extract_import(tree Tree) {
	mut imp_name := v.get_name(tree.child['Path'].tree, .snake_case, .other)#[1..-1].split('/').map(escape(it)).join('.')
	alias := v.get_name(tree.child['Name'].tree, .snake_case, .other)

	// `golang.org/x/net/html/atom` -> `net.html.atom`
	if imp_name.starts_with('golang.org.x.') {
		imp_name = imp_name[13..]
	}

	// get the `matched_val` value corresponding to the `imp_name`
	mut imp_name_parts := imp_name.split('.')
	mut matched_val := 'already correct import'
	parent: for key, val in module_equivalence {
		key_parts := key.split('.')
		for i, _ in key_parts {
			if key_parts[i].len > 1 && key_parts[i] != imp_name_parts[i] or { '' } {
				continue parent
			}
		}
		matched_val = val
		break
	}

	// use `matched_val`
	if matched_val.len > 1 {
		if matched_val != 'already correct import' {
			// import direct change
			if matched_val[matched_val.len - 1] != `.` {
				imp_name = matched_val
				// `new_import.` syntax
			} else {
				imp_name_parts[0] = matched_val#[..-1]
				imp_name = imp_name_parts.join('.')
			}
		}

		//	module html
		//	import net.html.atom
		// ->
		//	module html
		//	import atom
		imp_name = imp_name.split('${v.@module}.')[1] or { imp_name }

		v.imports[imp_name] = alias
	}
}

// extract the constant or the enum from a `Tree`
// as in Go enums are represented as constants, we use the same function for both
fn (mut v VAST) extract_const_or_enum(tree Tree, raw_enum_stmt NameFields, is_enum bool) NameFields {
	mut enum_stmt := raw_enum_stmt
	mut var_stmt := v.extract_variable(tree, false, false)
	var_stmt.middle = '='

	is_iota := var_stmt.values[0] or { bv_stmt('') } == bv_stmt('iota')

	if is_iota {
		// if it's the first field of the enum
		if !is_enum {
			enum_stmt.name = var_stmt.@type
			// delete type used as enum name (Go enums implentation is so weird)
			v.types.delete(var_stmt.@type)
		}

		enum_stmt.fields[var_stmt.names[0]] = bv_stmt('')
	} else if is_enum {
		enum_stmt.fields[var_stmt.names[0]] = var_stmt.values[0] or { bv_stmt('') }
	} else {
		v.consts << var_stmt
	}

	return enum_stmt
}

// extract the sumtype from a `Tree`
fn (mut v VAST) extract_sumtype(tree Tree) {
	v.types[v.get_name(tree, .camel_case, .global_decl)] = v.get_type(tree)
}

// extract the struct from a `Tree`
fn (mut v VAST) extract_struct(tree Tree, inline bool) string {
	name := if !inline {
		v.get_name(tree, .camel_case, .global_decl)
	} else {
		v.find_unused_name('Go2VInlineStruct', .in_global_scope)
	}

	// fix a bug with false/empty structs
	if name.len > 0 {
		mut @struct := Struct{
			name: name
		}
		temp := if !inline { tree.child['Type'].tree } else { tree }

		for _, field in temp.child['Fields'].tree.child['List'].tree.child {
			if 'Names' in field.tree.child {
				// support `A, B int` syntax
				for _, field_name in field.tree.child['Names'].tree.child {
					@struct.fields[v.get_name(field_name.tree, .snake_case, .field)] = BasicValueStmt{v.get_type(field.tree)}
				}
			} else {
				// struct embedding
				@struct.embedded_structs << v.get_type(field.tree)
			}
		}

		v.struct_fields.clear()

		mut already_defined := false
		mut already_defined_struct_name := name

		for defined_struct in v.structs {
			// test if the struct is the same except for the name
			mut temp_struct := defined_struct
			temp_struct.name = name

			if temp_struct == @struct {
				already_defined = true
				already_defined_struct_name = defined_struct.name
				break
			}
		}

		// if the struct is already defined we don't need to declare another exact same struct, we just need to point the name to the existing one
		if !already_defined {
			v.declared_global_old << name
			v.declared_global_new << name
			v.structs << @struct
		} else if !inline {
			v.declared_global_new[v.declared_global_new.index(name)] = already_defined_struct_name
		} else {
			v.declared_global_old << name
			v.declared_global_new << already_defined_struct_name
		}
	}

	return name
}

// extract the function from a `Tree`
fn (mut v VAST) extract_function(tree Tree, is_decl bool) FunctionStmt {
	mut func := FunctionStmt{
		type_ctx: !is_decl
	}

	raw_fn_name := if is_decl {
		v.get_name(tree, .snake_case, .fn_decl)
	} else {
		'x' + v.get_name(tree, .snake_case, .other)
	}
	if raw_fn_name.len > 0 {
		func.name = raw_fn_name[1..]
		func.public = raw_fn_name[0] == `v`
	}

	// comments on top functions (docstrings)
	if 'Doc' in tree.child {
		func.comment = '//' +
			tree.child['Doc'].tree.child['List'].tree.child['0'].tree.child['Text'].val#[3..-5].replace('\\n', '\n// ').replace('\\t', '\t')
	}

	// arguments
	for _, arg in tree.child['Type'].tree.child['Params'].tree.child['List'].tree.child {
		func.args[v.get_name(arg.tree.child['Names'].tree.child['0'].tree, .ignore, .other)] = v.get_type(arg.tree)
	}
	for _, @type in func.args {
		if @type == 'T' {
			func.generic = true
		}
	}

	// method
	if 'Recv' in tree.child {
		base := tree.child['Recv'].tree.child['List'].tree.child['0'].tree
		method_name := v.get_name(base.child['Names'].tree.child['0'].tree, .ignore, .other)
		method_type := v.get_type(base)
		v.current_method_var_name = method_name

		func.method = [
			if method_name.len > 0 { method_name } else { '_' },
			if method_type[0] == `&` { method_type[1..] } else { method_type },
		]
	}

	// return value(s)
	for _, arg in tree.child['Type'].tree.child['Results'].tree.child['List'].tree.child {
		func.ret_vals << v.get_type(arg.tree)

		// handle named return values
		if 'Names' in arg.tree.child {
			func.body << v.extract_variable(arg.tree, false, true)
		}
	}

	// body
	func.body << v.extract_body(tree.child['Body'].tree)

	if is_decl {
		v.current_method_var_name = ''
	}

	return func
}

// extract the function, if, for... body from a `Tree`
fn (mut v VAST) extract_body(tree Tree) []Statement {
	mut body := []Statement{}
	// all the variables declared after this limit will go out of scope at the end of the function
	limit := v.declared_vars_old.len

	// go through every statement
	for _, stmt in tree.child['List'].tree.child {
		body << v.extract_stmt(stmt.tree)
	}

	v.all_declared_vars << v.declared_vars_new
	v.declared_vars_old = v.declared_vars_old[..limit]
	v.declared_vars_new = v.declared_vars_new[..limit]

	return body
}

// extract the statement from a `Tree`
fn (mut v VAST) extract_stmt(tree Tree) Statement {
	mut ret := Statement(NotYetImplStmt{})

	match tree.name {
		// `var` syntax
		'*ast.DeclStmt' {
			mut var_stmt := v.extract_variable(tree.child['Decl'].tree.child['Specs'].tree.child['0'].tree,
				false, true)

			ret = var_stmt
		}
		// `:=`, `+=` etc. syntax
		'*ast.AssignStmt' {
			ret = v.extract_variable(tree, true, false)
		}
		// basic value
		'*ast.BasicLit', '*ast.StarExpr', '*ast.TypeAssertExpr' {
			ret = BasicValueStmt{v.get_name(tree, .ignore, .other)}
		}
		// variable, function call, etc.
		'*ast.Ident', '*ast.IndexExpr', '*ast.SelectorExpr' {
			ret = BasicValueStmt{v.get_name(tree, .snake_case, .other)}
			v.extract_embedded_declaration(tree)
		}
		'*ast.MapType' {
			ret = MapStmt{
				key_type: v.get_name(tree.child['Key'].tree, .ignore, .other)
				value_type: v.get_name(tree.child['Value'].tree, .ignore, .other)
			}
		}
		'*ast.ArrayType' {
			ret = ArrayStmt{
				@type: v.get_name(tree.child['Elt'].tree, .ignore, .other)
			}
		}
		// (almost) basic variable value
		// eg: -1
		'*ast.UnaryExpr' {
			op := if tree.child['Op'].val != 'range' { tree.child['Op'].val } else { '' }
			ret = ComplexValueStmt{
				op: op
				value: v.extract_stmt(tree.child['X'].tree)
			}
		}
		// arrays & `Struct{}` syntaxt
		'*ast.CompositeLit' {
			base := tree.child['Type'].tree

			match base.name {
				// arrays
				'*ast.ArrayType' {
					mut array := ArrayStmt{
						@type: v.get_type(tree).split(']')[1] // remove `[..]`
						len: v.stmt_to_string(v.extract_stmt(base.child['Len'].tree))
					}

					for _, el in tree.child['Elts'].tree.child {
						mut stmt := v.extract_stmt(el.tree)

						// inline structs with specific index
						if mut stmt is KeyValStmt {
							if mut stmt.value is StructStmt {
								stmt.value.name = array.@type
							}
							// inline structs
						} else if mut stmt is StructStmt {
							stmt.name = array.@type
						}

						array.values << stmt
					}

					// an ellipsis (`...`) used as the fixed-size array length in Go means that the length of the array is the number of elements it has
					if array.len == '... ' {
						array.len = array.values.len.str()
					}

					// []int{1, 2, 3} -> [1, 2, 3]
					// []int32{1, 2, 3} -> [i32(1), 2, 3]
					if array.values.len > 0 && array.@type !in transpiler.well_interpreted_types
						&& array.@type in v_types {
						array.values[0] = CallStmt{
							namespaces: array.@type
							args: [array.values[0]]
						}
					}

					ret = array
				}
				// structs
				'*ast.Ident', '', '*ast.SelectorExpr' {
					mut @struct := StructStmt{
						name: if base.name == '' {
							v.current_implicit_map_type
						} else {
							v.get_name(base, .ignore, .other)
						}
					}

					for _, el in tree.child['Elts'].tree.child {
						@struct.fields << v.extract_stmt(el.tree)
					}

					v.extract_embedded_declaration(base)

					ret = @struct
				}
				// maps
				'*ast.MapType' {
					map_type := v.get_type(tree)
					split_map_type := map_type.split(']')

					// short `{"key": "value"}` syntax
					v.current_implicit_map_type = map_type#[split_map_type[0].len + 1..]
					not_a_struct := v.current_implicit_map_type.len == 0
						|| v.current_implicit_map_type[0] == `[`

					mut map_stmt := MapStmt{
						key_type: split_map_type[0][4..]
						value_type: v.current_implicit_map_type
					}

					for _, el in tree.child['Elts'].tree.child {
						raw := v.extract_stmt(el.tree)

						if not_a_struct {
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

					v.extract_embedded_declaration(base)

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
				key: v.get_name(tree.child['Key'].tree, .snake_case, .other)
				value: v.extract_stmt(tree.child['Value'].tree)
			}
		}
		// slices (slicing)
		'*ast.SliceExpr' {
			mut slice_stmt := SliceStmt{
				value: v.get_name(tree.child['X'].tree, .ignore, .other)
				low: BasicValueStmt{}
				high: BasicValueStmt{}
			}
			if 'Low' in tree.child {
				slice_stmt.low = v.extract_stmt(tree.child['Low'].tree)
			}
			if 'High' in tree.child {
				slice_stmt.high = v.extract_stmt(tree.child['High'].tree)
			}
			ret = slice_stmt
		}
		// (nested) function/method call
		'*ast.ExprStmt', '*ast.CallExpr' {
			base := if tree.name == '*ast.ExprStmt' { tree.child['X'].tree } else { tree }

			fn_stmt := v.extract_function(base.child['Fun'].tree, false)
			if fn_stmt.body.len < 1 {
				mut call_stmt := CallStmt{
					namespaces: fn_stmt.name
				}
				// function/method arguments
				for _, arg in base.child['Args'].tree.child {
					call_stmt.args << v.extract_stmt(arg.tree)
				}

				// ellipsis (`...a` syntax)
				if base.child['Ellipsis'].val != '0' {
					idx := call_stmt.args.len - 1
					call_stmt.args[idx] = MultipleStmt{[bv_stmt('...'), call_stmt.args[idx]]}
				}

				// `[]byte("Hello, 世界")` -> `"Hello, 世界".bytes()`
				if fn_stmt.name[0] == `[` {
					call_stmt = CallStmt{
						namespaces: '${v.stmt_to_string(call_stmt.args[0])}.bytes'
					}
				}

				v.extract_embedded_declaration(base.child['Fun'].tree)

				ret = call_stmt
			} else {
				ret = fn_stmt
			}
		}
		// `i++` & `i--`
		'*ast.IncDecStmt' {
			ret = IncDecStmt{
				var: v.get_name(tree, .ignore, .other)
				inc: tree.child['Tok'].val
			}
		}
		// if/else
		'*ast.IfStmt' {
			mut if_stmt := IfStmt{}
			mut temp := tree
			mut next_is_end := if 'Else' in temp.child { false } else { true }

			for ('Else' in temp.child || next_is_end) {
				mut if_else := IfElse{}

				// `if z := 0; z < 10` syntax
				var := v.extract_variable(temp.child['Init'].tree, true, false)
				if var.names.len > 0 {
					if_stmt.init_vars << var
				}

				// condition
				if_else.condition = v.extract_stmt(temp.child['Cond'].tree)

				// body
				if_else.body << if 'Body' in temp.child {
					// `if` or `else if` branchs
					v.extract_body(temp.child['Body'].tree)
				} else {
					// `else` branchs
					v.extract_body(temp)
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
			for_stmt.init = v.extract_variable(tree.child['Init'].tree, true, false)
			for_stmt.init.mutable = false

			// condition
			for_stmt.condition = v.extract_stmt(tree.child['Cond'].tree)

			// post
			post_base := tree.child['Post'].tree
			if post_base.child.len > 0 {
				for_stmt.post = v.extract_stmt(post_base)
			}

			// body
			for_stmt.body = v.extract_body(tree.child['Body'].tree)

			ret = for_stmt
		}
		// break/continue
		'*ast.BranchStmt' {
			ret = BranchStmt{tree.child['Tok'].val, v.get_name(tree.child['Label'].tree,
				.snake_case, .other)}
		}
		// for in
		'*ast.RangeStmt' {
			mut forin_stmt := ForInStmt{}

			// classic syntax
			if tree.child['Tok'].val != 'ILLEGAL' {
				// idx
				forin_stmt.idx = v.get_name(tree.child['Key'].tree, .snake_case, .var_decl)

				// element & variable
				temp_var := v.extract_variable(tree.child['Key'].tree.child['Obj'].tree.child['Decl'].tree,
					true, false)
				forin_stmt.element = temp_var.names[1] or { '_' }
				forin_stmt.variable = temp_var.values[0] or { bv_stmt('_') }
			} else {
				// `for range variable {` syntax
				forin_stmt.variable = BasicValueStmt{v.get_name(tree, .snake_case, .other)}
			}

			// body
			forin_stmt.body = v.extract_body(tree.child['Body'].tree)

			ret = forin_stmt
		}
		'*ast.ReturnStmt' {
			mut return_stmt := ReturnStmt{}

			for _, el in tree.child['Results'].tree.child {
				return_stmt.values << v.extract_stmt(el.tree)
			}

			ret = return_stmt
		}
		'*ast.DeferStmt' {
			mut defer_stmt := DeferStmt{[v.extract_stmt(tree.child['Call'].tree)]}

			// as Go's defer stmt only support deferring one stmt, in Go if you want to defer multiple stmts you have to use an anonymous function, here we just extract the anonymous function's body
			if defer_stmt.body.len == 1 && defer_stmt.body[0] is FunctionStmt {
				defer_stmt.body = (defer_stmt.body[0] as FunctionStmt).body
			}

			ret = defer_stmt
		}
		'*ast.SwitchStmt', '*ast.TypeSwitchStmt' {
			is_type_switch := tree.name == '*ast.TypeSwitchStmt'
			mut match_stmt := MatchStmt{}

			if !is_type_switch {
				match_stmt.init = v.extract_variable(tree.child['Init'].tree, true, false)

				value := v.extract_stmt(tree.child['Tag'].tree)
				match_stmt.value = if value != bv_stmt('') {
					v.extract_stmt(tree.child['Tag'].tree)
				} else {
					bv_stmt('true')
				}
			} else {
				match_stmt.init = v.extract_variable(tree.child['Assign'].tree, true,
					false)

				value := if match_stmt.init.values.len == 0 {
					v.extract_stmt(tree.child['Assign'].tree.child['X'].tree.child['X'].tree)
				} else {
					match_stmt.init.values[0]
				}
				match_stmt.value = Statement(CallStmt{
					namespaces: '${v.stmt_to_string(value)}.type_name'
				})
			}

			// cases
			for _, case in tree.child['Body'].tree.child['List'].tree.child {
				mut match_case := MatchCase{
					values: v.extract_body(case.tree)
				}

				if is_type_switch {
					for mut value in match_case.values {
						if mut value is BasicValueStmt {
							value.value = "'$value.value'"
						}
					}
				}

				for _, case_stmt in case.tree.child['Body'].tree.child {
					match_case.body << v.extract_stmt(case_stmt.tree)
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
			ret = MultipleStmt{[
				v.extract_stmt(tree.child['X'].tree),
				bv_stmt(' ' + tree.child['Op'].val + ' '),
				v.extract_stmt(tree.child['Y'].tree),
			]}
		}
		'*ast.FuncLit' {
			ret = v.extract_function(tree, true)
		}
		'*ast.Ellipsis' {
			ret = bv_stmt('...')
		}
		'*ast.LabeledStmt' {
			ret = LabelStmt{v.get_name(tree.child['Label'].tree, .snake_case, .other), v.extract_stmt(tree.child['Stmt'].tree)}
		}
		'*ast.ParenExpr' {
			ret = bv_stmt('(' + v.stmt_to_string(v.extract_stmt(tree.child['X'].tree)) + ')')
		}
		'*ast.GoStmt' {
			to_call := v.extract_stmt(tree.child['Call'].tree)
			if to_call is FunctionStmt {
				mut multiple_stmts := MultipleStmt{}
				for _, child_stmt in to_call.body {
					multiple_stmts.stmts << GoStmt{child_stmt}
				}
				ret = multiple_stmts
			} else {
				ret = GoStmt{to_call}
			}
		}
		'*ast.BlockStmt' {
			ret = BlockStmt{v.extract_body(tree)}
		}
		'' {
			ret = bv_stmt('')
		}
		else {
			ret = not_implemented(tree)
		}
	}

	return v.stmt_transformer(ret)
}

// extract the variable from a `Tree`
fn (mut v VAST) extract_variable(tree Tree, short bool, force_decl bool) VariableStmt {
	left_hand := if short { tree.child['Lhs'].tree.child } else { tree.child['Names'].tree.child }
	right_hand := if short { tree.child['Rhs'].tree.child } else { tree.child['Values'].tree.child }

	mut var_stmt := VariableStmt{
		middle: if !force_decl { tree.child['Tok'].val } else { ':=' }
		@type: v.get_type(tree)
	}

	origin := if var_stmt.middle == ':=' { Origin.var_decl } else { Origin.other }

	for _, name in left_hand {
		var_stmt.names << v.get_name(name.tree, .snake_case, origin)
	}
	for _, val in right_hand {
		var_stmt.values << v.extract_stmt(val.tree)
	}

	return var_stmt
}
