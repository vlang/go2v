// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) stmt_list(list []Stmt) {
	for stmt in list {
		app.force_upper = false
		app.stmt(stmt)
	}
}

fn (mut app App) stmt(stmt Stmt) {
	match stmt {
		AssignStmt {
			app.assign_stmt(stmt, false) // no_mut:false
		}
		BlockStmt {
			// have to keep track of variable names which match outer scope, so they can be renamed in inner...
			app.block_stmt(stmt)
		}
		BranchStmt {
			app.branch_stmt(stmt)
		}
		DeclStmt {
			app.decl_stmt(stmt)
		}
		DeferStmt {
			app.defer_stmt(stmt)
		}
		ExprStmt {
			// app.genln('expr stmt')
			app.expr_stmt(stmt)
		}
		ForStmt {
			app.for_stmt(stmt)
		}
		GoStmt {
			app.go_stmt(stmt)
		}
		IfStmt {
			app.if_stmt(stmt)
		}
		IncDecStmt {
			app.inc_dec_stmt(stmt)
		}
		LabeledStmt {
			app.labeled_stmt(stmt)
		}
		RangeStmt {
			app.range_stmt(stmt)
		}
		ReturnStmt {
			app.return_stmt(stmt)
		}
		SwitchStmt {
			app.switch_stmt(stmt)
		}
		SendStmt {
			app.send_stmt(stmt)
		}
		TypeSwitchStmt {
			app.type_switch_stmt(stmt)
		}
		else {
			app.genln('\t// unhandled in stmt: ${stmt}')
		} // Add additional handlers as needed
	}
}

fn (mut app App) block_stmt(body BlockStmt) {
	app.genln('{')
	// Initialize named return params at the start of the function body
	// This is needed when the named return param is used before being assigned
	// (e.g., `result = append(result, ...)` uses result on RHS)
	if app.pending_named_returns {
		for name, typ in app.named_return_types {
			v_name := app.go2v_ident(name)
			// For function array types, use explicit type annotation: mut x: []fn() = []
			// because V parses []fn() as [] followed by fn() call
			mut is_fn_array := false
			match typ {
				ArrayType {
					if typ.elt is FuncType || typ.elt is ParenExpr {
						is_fn_array = true
					}
				}
				else {}
			}
			if is_fn_array {
				// For function arrays, V can't parse []fn(){} correctly
				// Use map[int]fn(){}.values() as workaround
				arr := typ as ArrayType
				app.gen('mut ${v_name} := map[int]')
				app.force_upper = true
				elt := arr.elt
				match elt {
					FuncType {
						app.func_type(elt)
					}
					ParenExpr {
						if elt.x is FuncType {
							app.func_type(elt.x)
						}
					}
					else {
						app.expr(elt)
					}
				}
				app.gen('{}.values()')
			} else {
				app.gen('mut ${v_name}:=')
				app.gen_zero_value(typ)
			}
			app.genln('')
			app.cur_fn_names[v_name] = true
		}
	}
	app.pending_named_returns = false
	app.stmt_list(body.list)
	app.genln('}')
}

// branch_stmt handles continue break etc
fn (mut app App) branch_stmt(node BranchStmt) {
	app.gen(node.tok)
	if node.label.name != '' {
		app.gen(' ' + node.label.name)
	}
	app.genln('')
}

fn (mut app App) decl_stmt(d DeclStmt) {
	match d.decl {
		GenDecl {
			if d.decl.tok == 'var' {
				for spec in d.decl.specs {
					match spec {
						ValueSpec {
							app.gen('mut ')
							for idx in 0 .. spec.names.len {
								if idx > 0 {
									app.gen(',')
								}
								go_name := spec.names[idx].name
								v_name := app.go2v_ident(go_name)
								n := app.unique_name_anti_shadow(v_name)
								app.gen(n)
								app.cur_fn_names[n] = true
								// Update name_mapping if the name was changed due to shadowing
								if n != v_name {
									app.name_mapping[go_name] = n
								}
							}
							app.gen(' := ')

							cast := if spec.typ is Ident {
								ident := spec.typ as Ident
								type_info := go2v_type_checked(ident.name)
								if type_info.is_basic {
									type_info.v_type
								} else {
									mut c := go2v_type(ident.name.to_lower())
									for n in spec.names {
										if app.go2v_ident(n.name) == c {
											app.force_upper = true
											c = app.go2v_ident(ident.name)
											break
										}
									}
									c
								}
							} else {
								''
							}
							if spec.values.len == 0 {
								// Handle function type variables (zero value is unsafe { nil })
								if spec.typ is FuncType {
									app.gen('unsafe { nil }')
									continue
								}
								// For struct/named types (Ident), generate Type{}
								// But NOT for basic types like string, int, etc.
								if spec.typ is Ident {
									ident := spec.typ as Ident
									if ident.name != '' {
										// Check if it's a basic type
										type_info := go2v_type_checked(ident.name)
										if type_info.is_basic {
											// For basic types, use gen_zero_value
											app.gen_zero_value(spec.typ)
											app.genln('')
											continue
										}
										// For custom/struct types, generate Type{}
										app.force_upper = true
										app.gen(app.go2v_ident(ident.name))
										app.genln('{}')
										continue
									}
								}
								// Handle SelectorExpr types (e.g., strings.Builder)
								if spec.typ is SelectorExpr {
									sel := spec.typ as SelectorExpr
									if sel.x is Ident {
										mod := (sel.x as Ident).name
										type_name := sel.sel.name
										// strings.Builder => strings.new_builder(0)
										if mod == 'strings' && type_name == 'Builder' {
											app.require_import('strings')
											app.genln('strings.new_builder(0)')
											continue
										}
										// bytes.Buffer => strings.new_builder(0) (V uses strings.Builder for both)
										if mod == 'bytes' && type_name == 'Buffer' {
											app.require_import('strings')
											app.genln('strings.new_builder(0)')
											continue
										}
										// Other types: mod.TypeName{}
										app.gen('${mod}.${type_name}')
										app.genln('{}')
										continue
									}
								}
								// Handle ArrayType (e.g., [4]byte or []Type)
								if spec.typ is ArrayType {
									arr := spec.typ as ArrayType
									app.gen('[')
									// Only generate length for fixed-size arrays, not slices
									if arr.len !is InvalidExpr {
										app.expr(arr.len)
									}
									app.gen(']')
									app.force_upper = true
									app.expr(arr.elt)
									app.genln('{}')
									continue
								}
								app.force_upper = true
								if cast != '' {
									app.gen('${cast}(')
								}
								app.gen_zero_value(spec.typ)
								if cast != '' {
									app.genln(')')
								}
								continue
							}
							for idx in 0 .. spec.values.len {
								if idx > 0 {
									app.gen(',')
								}
								value := spec.values[idx]
								mut needs_cast := false
								match value {
									BasicLit {
										if value.kind != 'CHAR' {
											kind := if cast != '' {
												cast
											} else {
												go2v_type(value.kind.to_lower())
											}
											if kind != value.kind.to_lower() {
												app.gen('${kind}(')
												needs_cast = true
											}
										}
									}
									else {}
								}
								app.expr(spec.values[idx])
								if needs_cast {
									app.gen(')')
								}
							}
						}
						else {
							app.gen('// UNHANDLED DeclStmt-GenDecl spec')
						}
					}
				}
			}
		}
		else {
			app.gen('// UNHANDLED DeclStmt')
		}
	}
	app.genln('')
}

fn (mut app App) defer_stmt(node DeferStmt) {
	app.gen('defer ')
	// `defer fn() { ... } ()
	// empty function, just generate `defer { ... }` in V

	was_in_defer := app.in_defer_block
	app.in_defer_block = true

	if node.call is CallExpr && node.call.args.len == 0 {
		if node.call.fun is FuncLit {
			func_lit := node.call.fun as FuncLit
			app.block_stmt(func_lit.body)
		} else {
			// Simple function call with no args: defer foo() => defer { foo() }
			app.genln('{')
			app.expr(node.call.fun)
			app.genln('()')
			app.genln('}')
		}
	} else {
		app.genln('{')
		app.expr(node.call)
		app.genln('}')
	}

	app.in_defer_block = was_in_defer
}

fn (mut app App) expr_stmt(stmt ExprStmt) {
	// Handle channel receive as statement: <-ch needs to become _ := <-ch in V
	if stmt.x is UnaryExpr {
		u := stmt.x as UnaryExpr
		if u.op == '<-' {
			app.gen('_ := ')
		}
	}
	// Check if this is a method call that needs error handling in V
	// (methods like write, write_string that return !int)
	needs_error_handling := app.call_needs_error_handling(stmt.x)
	// Mark that we're at statement level (safe to emit temp var declarations)
	was_at_stmt_level := app.at_stmt_level
	app.at_stmt_level = true
	app.expr(stmt.x)
	app.at_stmt_level = was_at_stmt_level
	if needs_error_handling {
		app.gen(' or { }')
	}
	app.genln('')
}

// Check if a call expression needs error handling when used as a statement
// This handles methods that return error types in V but whose return values
// are typically ignored in Go (like strings.Builder.Write)
fn (app App) call_needs_error_handling(e Expr) bool {
	if e is CallExpr {
		fun := e.fun
		if fun is SelectorExpr {
			// Check for specific method names that need error handling
			// Note: in V, strings.Builder.write() returns !int but write_string() doesn't
			method_name := fun.sel.name
			if method_name == 'Write' {
				return true
			}
		}
	}
	return false
}

fn (mut app App) for_stmt(f ForStmt) {
	app.gen('for ')

	init_empty := f.init.node_type == '' // f.init is InvalidStmt // f.init.node_type == ''
	cond_empty := f.cond is InvalidExpr
	post_empty := f.post is InvalidStmt

	if init_empty && cond_empty && post_empty {
		app.block_stmt(f.body)
		return
	}
	// for cond {
	if init_empty && !cond_empty && post_empty {
		app.expr(f.cond)
		app.block_stmt(f.body)
		return
	}
	// for ; cond ; post {
	if init_empty && !cond_empty && !post_empty {
		app.gen('; ')
		app.expr(f.cond)
		app.gen('; ')
		if !post_empty {
			app.stmt(f.post)
		}
		app.block_stmt(f.body)
		return
	}
	// for init; cond; post {
	// Track which variables are declared in the init (they're scoped to the loop)
	mut loop_vars := []string{}
	if f.init.lhs.len > 0 && f.init.tok == ':=' {
		for lhs in f.init.lhs {
			if lhs is Ident {
				loop_vars << app.go2v_ident(lhs.name)
			}
		}
	}
	app.assign_stmt(f.init, true)
	app.gen('; ')
	app.expr(f.cond)
	app.gen('; ')
	if !post_empty {
		app.stmt(f.post)
	}
	app.block_stmt(f.body)
	// Remove for loop variables from cur_fn_names since they're scoped to the loop
	for v in loop_vars {
		app.cur_fn_names.delete(v)
	}
}

fn (mut app App) go_stmt(stmt GoStmt) {
	app.gen('spawn ')
	app.in_go_stmt = true
	app.expr(stmt.call)
	app.in_go_stmt = false
}

fn (mut app App) if_stmt(node IfStmt) {
	if node.init.tok != '' {
		// Check if the init contains an atomic.Add operation that needs splitting
		if app.is_atomic_add_init(node.init) {
			app.handle_atomic_add_init(node.init)
		} else {
			app.assign_stmt(node.init, false)
		}
	}

	app.gen('if ')
	app.expr(node.cond)
	app.block_stmt(node.body)
	if node.else_ is IfStmt {
		app.genln('else')
		if node.else_.init.tok != '' {
			// handle `else if x, ok := ...; ok {`  => `else { mut ok ... if ...  }`
			app.genln('{')
			// app.genln('//LOOL0')
		}
		app.if_stmt(node.else_)
		if node.else_.init.tok != '' {
			app.genln('}')
		}
	} else if node.else_ is BlockStmt {
		app.genln('else')
		app.block_stmt(node.else_)
	}
}

// Check if the init statement contains an atomic.Add operation
fn (app App) is_atomic_add_init(init AssignStmt) bool {
	if init.rhs.len == 0 {
		return false
	}
	if init.rhs[0] is CallExpr {
		call := init.rhs[0] as CallExpr
		if call.fun is SelectorExpr {
			sel := call.fun as SelectorExpr
			if sel.x is Ident {
				ident := sel.x as Ident
				if ident.name == 'atomic' && sel.sel.name.starts_with('Add') {
					return true
				}
			}
		}
	}
	return false
}

// Handle atomic.Add in if init by splitting into separate statements
fn (mut app App) handle_atomic_add_init(init AssignStmt) {
	// For: counter := atomic.AddInt32(&wg.counter, delta)
	// Generate:
	//   wg.counter += delta
	//   mut counter := wg.counter
	if init.rhs.len > 0 && init.rhs[0] is CallExpr {
		call := init.rhs[0] as CallExpr
		if call.args.len >= 2 {
			// Generate the add operation
			if call.args[0] is UnaryExpr {
				ux := call.args[0] as UnaryExpr
				app.expr(ux.x)
				app.gen(' += ')
				app.expr(call.args[1])
				app.genln('')
				// Generate the variable declaration
				for l_idx, lhs_expr in init.lhs {
					if l_idx == 0 {
						app.gen('mut ')
					} else {
						app.gen(', ')
					}
					if lhs_expr is Ident {
						n := app.go2v_ident(lhs_expr.name)
						app.cur_fn_names[n] = true
						app.gen(n)
					} else {
						app.expr(lhs_expr)
					}
				}
				app.gen(' := ')
				app.expr(ux.x)
				app.genln('')
				return
			}
		}
	}
	// Fallback to regular assignment
	app.assign_stmt(init, false)
}

fn (mut app App) inc_dec_stmt(i IncDecStmt) {
	// Handle dereferenced pointer increment/decrement: *ptr++ -> ptr[0]++
	match i.x {
		StarExpr {
			app.expr(i.x.x)
			app.genln('[0]${i.tok}')
			return
		}
		else {}
	}
	app.expr(i.x)
	app.genln(i.tok)
}

fn (mut app App) labeled_stmt(l LabeledStmt) {
	app.genln('${l.label.name}:')
	app.stmt(l.stmt)
}

fn (mut app App) range_stmt(node RangeStmt) {
	value_is_mut := node.value.name != '' && node.value.name != '_'
		&& app.is_assigned_in_block(node.value.name, node.body)

	app.gen('for ')
	if (node.key.name == '_' || node.key.name == '') && node.value.name != '' {
		v_val := app.go2v_ident(node.value.name)
		value_name := app.unique_name_anti_shadow(v_val)
		app.cur_fn_names[value_name] = true
		if value_name != v_val {
			app.name_mapping[node.value.name] = value_name
		}
		if value_is_mut {
			app.gen('mut ')
		}
		app.gen(value_name)
		app.gen(' in ')
		app.expr(node.x)
		app.gen(' ')
		app.block_stmt(node.body)
		return
	}
	// Both key and value are present
	// if node.key.name != node.value.name {
	if node.key.name == '' {
		app.gen('_ ')
	} else {
		v_key := app.go2v_ident(node.key.name)
		key_name := app.unique_name_anti_shadow(v_key)
		app.cur_fn_names[key_name] = true
		// Add mapping if name was changed due to shadowing
		if key_name != v_key {
			app.name_mapping[node.key.name] = key_name
		}
		// Do NOT add `mut` to the key — V forbids mut on map/array keys in for-range
		app.gen(key_name)
		app.gen(', ')
		if node.value.name == '' {
			app.gen(' _ ')
		} else {
			v_val := app.go2v_ident(node.value.name)
			value_name := app.unique_name_anti_shadow(v_val)
			app.cur_fn_names[value_name] = true
			// Add mapping if name was changed due to shadowing
			if value_name != v_val {
				app.name_mapping[node.value.name] = value_name
			}
			if value_is_mut {
				app.gen('mut ')
			}
			app.gen(value_name)
		}
	}
	app.gen(' in ')
	app.expr(node.x)
	app.gen(' ')
	app.block_stmt(node.body)
}

// is_assigned_in_block checks if a variable name is assigned to within a block statement
fn (app App) is_assigned_in_block(name string, block BlockStmt) bool {
	for stmt in block.list {
		if app.is_assigned_in_stmt(name, stmt) {
			return true
		}
	}
	return false
}

// is_assigned_in_stmt recursively checks if a variable is assigned in a statement
fn (app App) is_assigned_in_stmt(name string, stmt Stmt) bool {
	match stmt {
		AssignStmt {
			// Only check = assignments, not := declarations
			// := creates a new variable, = modifies an existing one
			if stmt.tok == '=' {
				// Check if the variable is on the left side of an assignment
				for lhs in stmt.lhs {
					if lhs is Ident && lhs.name == name {
						return true
					}
				}
			}
		}
		BlockStmt {
			return app.is_assigned_in_block(name, stmt)
		}
		IfStmt {
			if app.is_assigned_in_block(name, stmt.body) {
				return true
			}
			// Check else branch - recursively check the else_ statement
			if app.is_assigned_in_stmt(name, stmt.else_) {
				return true
			}
		}
		ForStmt {
			if app.is_assigned_in_block(name, stmt.body) {
				return true
			}
		}
		RangeStmt {
			if app.is_assigned_in_block(name, stmt.body) {
				return true
			}
		}
		SwitchStmt {
			if app.is_assigned_in_block(name, stmt.body) {
				return true
			}
		}
		TypeSwitchStmt {
			if app.is_assigned_in_block(name, stmt.body) {
				return true
			}
		}
		CaseClause {
			// Check statements inside the case clause body
			for case_stmt in stmt.body {
				if app.is_assigned_in_stmt(name, case_stmt) {
					return true
				}
			}
		}
		else {}
	}
	return false
}

// Check if expression is a module-qualified composite literal (e.g., api.WatchOptions{})
// V's parser has issues with these in certain contexts (function arguments, multi-value returns)
fn (app App) needs_temp_var(expr Expr) bool {
	if expr is CompositeLit {
		// Only module-qualified types (SelectorExpr) need extraction
		return expr.typ is SelectorExpr
	}
	return false
}

// Extract all nested module-qualified composite literals from a composite literal
// Returns a map from field index to temp var name
fn (mut app App) extract_nested_structs(c CompositeLit) map[int]string {
	mut nested_temps := map[int]string{}
	for i, elt in c.elts {
		if elt is KeyValueExpr {
			if app.needs_temp_var(elt.value) {
				// Recursively extract nested structs from the nested struct first
				nested_cl := elt.value as CompositeLit
				inner_temps := app.extract_nested_structs(nested_cl)

				// Now generate the nested struct with any inner temp var substitutions
				temp_name := 'go2v_tmp_${app.temp_var_count}'
				app.temp_var_count++
				app.gen('${temp_name} := ')
				app.composite_lit_with_temps(nested_cl, inner_temps)
				app.genln('')
				nested_temps[i] = temp_name
			}
		}
	}
	return nested_temps
}

// Generate a composite literal using pre-extracted temp vars for nested structs
fn (mut app App) composite_lit_with_temps(c CompositeLit, temps map[int]string) {
	if c.typ !is SelectorExpr {
		app.composite_lit(c)
		return
	}

	force_upper := app.force_upper
	app.force_upper = true
	app.selector_expr(c.typ as SelectorExpr)
	app.force_upper = force_upper

	app.gen('{')
	if c.elts.len > 0 {
		app.genln('')
	}
	for i, elt in c.elts {
		if i in temps {
			// Use the pre-extracted temp var
			if elt is KeyValueExpr {
				if elt.key is Ident {
					app.gen('\t${app.go2v_ident(elt.key.name)}: ${temps[i]}')
				} else {
					app.expr(elt.key)
					app.gen(': ${temps[i]}')
				}
				app.genln('')
			}
		} else {
			app.expr(elt)
			app.genln('')
		}
	}
	app.gen('}')
}

// Extract composite literals with SelectorExpr type to temporary variables
// Returns list of (temp_var_name, expr) pairs
fn (mut app App) extract_temp_vars(exprs []Expr) ([]Expr, []string) {
	mut result := []Expr{cap: exprs.len}
	mut temp_names := []string{}
	for expr in exprs {
		if app.needs_temp_var(expr) {
			temp_name := 'go2v_tmp_${app.temp_var_count}'
			app.temp_var_count++
			// Emit the temp variable declaration
			app.gen('${temp_name} := ')
			app.expr(expr)
			app.genln('')
			// Use Ident to reference the temp var later
			result << Ident{
				name: temp_name
			}
			temp_names << temp_name
		} else {
			result << expr
		}
	}
	return result, temp_names
}

fn (mut app App) return_stmt(node ReturnStmt) {
	// V doesn't allow return inside defer blocks
	if app.in_defer_block {
		app.genln('// return inside defer not supported in V')
		return
	}

	// Handle bare return with named return parameters
	if node.results.len == 0 && app.named_return_types.len > 0 {
		app.gen('return ')
		mut first := true
		for name, _ in app.named_return_types {
			if !first {
				app.gen(', ')
			}
			app.gen(app.go2v_ident(name))
			first = false
		}
		app.genln('')
		return
	}

	// Handle return nil for array/map types - convert to empty array/map
	if node.results.len == 1 && app.named_return_types.len == 1 {
		result := node.results[0]
		if result is Ident && result.name == 'nil' {
			// Get the single return type
			for _, typ in app.named_return_types {
				match typ {
					ArrayType {
						app.gen('return ')
						app.force_upper = true
						app.array_type(typ)
						app.genln('{}')
						return
					}
					MapType {
						app.gen('return ')
						app.map_type(typ)
						app.genln('{}')
						return
					}
					else {}
				}
			}
		}
	}

	// For multi-value returns with module-qualified composite literals,
	// extract to temp vars first. V's parser has issues with: return api.Type{}, nil, err
	if node.results.len > 1 {
		mut temp_names := []string{}
		for result in node.results {
			if app.needs_temp_var(result) {
				cl := result as CompositeLit
				// First extract any nested module-qualified structs
				nested_temps := app.extract_nested_structs(cl)

				// Generate the temp var with nested temps already extracted
				temp_name := 'go2v_tmp_${app.temp_var_count}'
				app.temp_var_count++
				app.gen('${temp_name} := ')
				app.composite_lit_with_temps(cl, nested_temps)
				app.genln('')
				temp_names << temp_name
			} else {
				temp_names << ''
			}
		}
		app.gen('return ')
		for i, result in node.results {
			if temp_names[i] != '' {
				app.gen(temp_names[i])
			} else {
				app.expr(result)
			}
			if i < node.results.len - 1 {
				app.gen(', ')
			}
		}
		app.genln('')
	} else {
		app.gen('return ')
		for i, result in node.results {
			app.expr(result)
			if i < node.results.len - 1 {
				app.gen(',')
			}
		}
		app.genln('')
	}
}

fn (mut app App) send_stmt(node SendStmt) {
	app.expr(node.chan_)
	app.gen(' <- ')
	// Handle struct{}{} (empty struct value) by sending true for chan bool
	if node.value is CompositeLit {
		cl := node.value as CompositeLit
		if cl.typ is StructType {
			st := cl.typ as StructType
			if st.fields.list.len == 0 {
				app.genln('true')
				return
			}
		}
	}
	app.expr(node.value)
	app.genln('')
}
