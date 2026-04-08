// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) unique_name_anti_shadow(n string, force_rename ...bool) string {
	if n == '_' {
		return '_'
	}
	// If force_rename is false (default) and name not in scope, return as-is
	if (force_rename.len == 0 || !force_rename[0]) && n !in app.cur_fn_names {
		return n
	}
	// Increase the i in `name_i` until it's unique.
	mut i := 1
	mut res := ''
	for {
		res = '${n}_${i}'

		if res !in app.cur_fn_names {
			break
		}
		i++
		if i > 100 {
			panic('100 levels of shadowing, that cannot be real!')
		}
	}
	// res := n + rand.intn(10000) or { 0 }.str() // LOL fix this
	return res
}

// Check if an expression contains a reference to a specific identifier
fn (app App) expr_contains_ident(e Expr, name string) bool {
	match e {
		Ident {
			return e.name == name
		}
		CallExpr {
			// Check function name and all arguments
			if app.expr_contains_ident(e.fun, name) {
				return true
			}
			for arg in e.args {
				if app.expr_contains_ident(arg, name) {
					return true
				}
			}
		}
		BinaryExpr {
			return app.expr_contains_ident(e.x, name) || app.expr_contains_ident(e.y, name)
		}
		UnaryExpr {
			return app.expr_contains_ident(e.x, name)
		}
		SelectorExpr {
			return app.expr_contains_ident(e.x, name)
		}
		IndexExpr {
			return app.expr_contains_ident(e.x, name) || app.expr_contains_ident(e.index, name)
		}
		SliceExpr {
			if app.expr_contains_ident(e.x, name) {
				return true
			}
			if e.low !is InvalidExpr && app.expr_contains_ident(e.low, name) {
				return true
			}
			if e.high !is InvalidExpr && app.expr_contains_ident(e.high, name) {
				return true
			}
		}
		StarExpr {
			return app.expr_contains_ident(e.x, name)
		}
		ParenExpr {
			return app.expr_contains_ident(e.x, name)
		}
		CompositeLit {
			for elt in e.elts {
				if app.expr_contains_ident(elt, name) {
					return true
				}
			}
		}
		KeyValueExpr {
			return app.expr_contains_ident(e.key, name) || app.expr_contains_ident(e.value, name)
		}
		else {}
	}
	return false
}

fn (mut app App) assign_stmt(assign AssignStmt, no_mut bool) {
	app.track_string_key_map_vars(assign)

	// Pre-extract temp vars for module-qualified composite literals in RHS call expressions
	// This must be done BEFORE generating the assignment to avoid breaking the syntax
	// We track extracted args so call_expr can use the temp var instead of re-extracting
	for rhs_expr in assign.rhs {
		if rhs_expr is CallExpr {
			// Check call arguments for module-qualified composite literals
			for i, arg in rhs_expr.args {
				if app.needs_temp_var(arg) {
					temp_name := 'go2v_tmp_${app.temp_var_count}'
					app.temp_var_count++
					app.gen('${temp_name} := ')
					app.expr(arg)
					app.genln('')
					// Track this for call_expr - use arg index as key
					app.call_arg_temp_vars['${i}'] = temp_name
				}
			}
		}
	}
	defer {
		app.call_arg_temp_vars.clear()
	}

	// Check if we need unsafe block for pointer dereference on LHS
	mut needs_unsafe := false
	for lhs_expr in assign.lhs {
		if lhs_expr is StarExpr {
			needs_unsafe = true
			break
		}
	}
	if needs_unsafe {
		app.gen('unsafe { ')
		app.in_unsafe_block = true
	}

	// Special case for 'append()' => '<<' - check this first before generating LHS
	// because we don't want to add 'mut' for append operations
	if app.check_and_handle_append_early(assign) {
		if needs_unsafe {
			app.gen(' }')
			app.in_unsafe_block = false
		}
		return
	}

	// Special case for type assertion with comma-ok pattern: val, ok := x.(Type)
	if app.check_and_handle_type_assertion(assign) {
		return
	}

	// Special case for os.LookupEnv: value, ok := os.LookupEnv("X") => Go's (string, bool) to V's ?string
	if app.check_and_handle_lookup_env(assign) {
		return
	}

	// Special case for map lookup with comma-ok pattern: value, ok := myMap[key]
	if app.check_and_handle_map_lookup_ok(assign) {
		return
	}

	// Special case for channel receive with comma-ok pattern: value, ok := <-ch
	if app.check_and_handle_chan_recv_ok(assign) {
		return
	}

	// Special case for functions that return (value, error) like strconv.Atoi
	if app.check_and_handle_result_pattern(assign) {
		return
	}

	// Check if this is an assignment to a named return param that needs to be converted to declaration
	// But only if the LHS variable is NOT used on the RHS (to avoid circular reference)
	mut convert_to_decl := false
	if assign.tok == '=' && assign.lhs.len == 1 {
		if assign.lhs[0] is Ident {
			lhs_ident := assign.lhs[0] as Ident
			lhs_name := lhs_ident.name
			if lhs_name in app.named_return_params && lhs_name !in app.cur_fn_names {
				// Check if lhs_name is used in RHS - if so, don't convert to declaration
				// because the variable needs to be pre-declared for the RHS to reference it
				mut used_in_rhs := false
				for rhs in assign.rhs {
					if app.expr_contains_ident(rhs, lhs_name) {
						used_in_rhs = true
						break
					}
				}
				if !used_in_rhs {
					convert_to_decl = true
				}
			}
		}
	}

	// Collect pending name mappings - don't apply until after RHS processing
	// This ensures that `x := x + 1` uses the outer x on RHS, not the new x
	mut pending_mappings := map[string]string{}

	// Collect LHS names to add to cur_fn_names AFTER RHS processing
	// This prevents closures in RHS from incorrectly capturing LHS variables
	mut lhs_names_to_add := []string{}

	for l_idx, lhs_expr in assign.lhs {
		if l_idx == 0 {
			match lhs_expr {
				Ident {
					if lhs_expr.name != '_' {
						if !no_mut {
							if assign.tok == ':=' || convert_to_decl {
								app.gen('mut ')
							}
						}
					}
				}
				else {}
			}
		} else {
			app.gen(', ')
		}
		if lhs_expr is Ident {
			// Handle shadowing - convert to V name first before checking
			go_name := lhs_expr.name // Original Go name
			mut n := app.go2v_ident(go_name)
			// Check for shadowing: either name already exists in scope, or
			// the name appears in the RHS (self-referential declaration like `x := func(x)`)
			mut needs_rename := n in app.cur_fn_names
			if !needs_rename && (assign.tok == ':=' || convert_to_decl) && n != '_' {
				// Check if this name appears in any RHS expression (self-referential declaration)
				for rhs_expr in assign.rhs {
					if app.expr_contains_ident(rhs_expr, go_name) {
						needs_rename = true
						break
					}
				}
			}
			if (assign.tok == ':=' || convert_to_decl) && n != '_' && needs_rename {
				n = app.unique_name_anti_shadow(n, true)
				// Queue the mapping for later - don't apply yet
				pending_mappings[go_name] = n
			}
			// Don't add to cur_fn_names yet - wait until after RHS is processed
			// This prevents closures from incorrectly capturing LHS variables
			if n != '_' {
				lhs_names_to_add << n
			}
			app.gen(n)
		} else if lhs_expr is StarExpr {
			// Can't use star_expr(), since it generates &
			app.gen('*')
			app.expr(lhs_expr.x)
		} else {
			app.expr(lhs_expr)
		}
	}

	// Use := for named return param conversion
	if convert_to_decl {
		app.gen(':=')
	} else {
		app.gen(assign.tok)
	}

	// Check if this is a declaration (needs type casts) or reassignment (doesn't need them)
	is_declaration := assign.tok == ':=' || convert_to_decl

	for r_idx, rhs_expr in assign.rhs {
		mut needs_close_paren := false
		if r_idx > 0 {
			app.gen(', ')
		}
		// Only add type casts for declarations, not reassignments
		// For reassignments, the variable's type is already determined
		if is_declaration {
			match rhs_expr {
				BasicLit {
					v_kind := rhs_expr.kind.to_lower()
					if v_kind != 'int' && v_kind != 'string' {
						app.gen('${go2v_type(v_kind)}(')
						needs_close_paren = true
					} else {
						v_type := go2v_type(v_kind)
						if v_type != v_kind {
							app.gen(go2v_type(v_kind))
							app.gen('(')
							needs_close_paren = true
						}
					}
				}
				else {}
			}
		}
		app.expr(rhs_expr)
		if needs_close_paren {
			app.gen(')')
		}
	}

	// Now apply the pending name mappings after RHS has been processed
	for go_name, v_name in pending_mappings {
		app.name_mapping[go_name] = v_name
	}

	// Now register LHS names in cur_fn_names (after RHS processing)
	// This ensures closures in RHS don't incorrectly capture LHS variables
	for n in lhs_names_to_add {
		app.cur_fn_names[n] = true
	}

	if needs_unsafe {
		app.gen(' }')
		app.in_unsafe_block = false
	}
	app.genln('')
}

fn (mut app App) track_string_key_map_vars(assign AssignStmt) {
	if assign.lhs.len != 1 || assign.rhs.len != 1 {
		return
	}
	if assign.lhs[0] !is Ident {
		return
	}
	var_name := (assign.lhs[0] as Ident).name
	rhs_expr := assign.rhs[0]
	if rhs_expr is CompositeLit {
		cl := rhs_expr as CompositeLit
		if cl.typ is MapType && app.map_key_forced_to_string(cl.typ as MapType) {
			app.map_string_key_vars[var_name] = true
		}
		return
	}
	if rhs_expr is CallExpr {
		call := rhs_expr as CallExpr
		if call.fun is Ident && (call.fun as Ident).name == 'make' && call.args.len > 0 {
			if call.args[0] is MapType && app.map_key_forced_to_string(call.args[0] as MapType) {
				app.map_string_key_vars[var_name] = true
			}
		}
	}
}

fn (app App) map_key_forced_to_string(map_type MapType) bool {
	match map_type.key {
		Ident {
			return map_type.key.name in app.struct_types
		}
		SelectorExpr {
			return true
		}
		else {
			return false
		}
	}
}

fn (mut app App) is_append_call(assign AssignStmt) bool {
	if assign.rhs.len == 0 {
		return false
	}
	first_rhs := assign.rhs[0]
	if first_rhs is CallExpr {
		fun := first_rhs.fun
		if fun is Ident {
			if fun.name == 'append' {
				return true
			}
		}
	}
	return false
}

fn (mut app App) check_and_handle_append_early(assign AssignStmt) bool {
	if !app.is_append_call(assign) {
		return false
	}
	// Generate LHS without mut
	for l_idx, lhs_expr in assign.lhs {
		if l_idx > 0 {
			app.gen(', ')
		}
		app.expr(lhs_expr)
	}
	first_rhs := assign.rhs[0]
	if first_rhs is CallExpr {
		app.gen_append(first_rhs.args, assign.tok)
	}
	return true
}

fn (mut app App) check_and_handle_append(assign AssignStmt) bool {
	if assign.rhs.len == 0 {
		app.genln('// append no rhs')
		return false
	}
	first_rhs := assign.rhs[0]
	if first_rhs is CallExpr {
		fun := first_rhs.fun
		if fun is Ident {
			if fun.name == 'append' {
				app.gen_append(first_rhs.args, assign.tok)
				return true
			}
		}
	}
	return false
}

fn (mut app App) gen_append(args []Expr, assign_tok string) {
	// Handle special case `mut x := arr.clone()`
	// In Go it's
	// `append([]Foo{}, foo...)`

	arg0 := args[0]
	if arg0 is CompositeLit && arg0.typ is ArrayType {
		app.gen(' ${assign_tok} ')
		app.expr(args[1])
		app.gen('.')
		app.genln('clone()')
		return
	}

	app.gen(' << ')
	if args.len == 2 {
		app.expr(args[1])
		app.genln('')
		return
	}

	for i := 1; i < args.len; i++ {
		arg_i := args[i]
		match arg_i {
			BasicLit {
				v_kind := go2v_type(arg_i.kind.to_lower())
				needs_cast := v_kind != 'int'
				if i == 1 {
					app.gen('[')
					if needs_cast {
						app.gen('${go2v_type(v_kind)}(')
					}
				}
				app.expr(arg_i)
				if i == 1 && needs_cast {
					app.gen(')')
				}
				if i < args.len - 1 {
					app.gen(',')
				} else if i == args.len - 1 {
					app.gen(']')
				}
			}
			else {
				if i == 1 {
					app.gen('[')
				}
				app.expr(arg_i)
				if i < args.len - 1 {
					app.gen(',')
				} else if i == args.len - 1 {
					app.gen(']')
				}
			}
		}
	}
	app.genln('')
}

// Check and handle os.LookupEnv pattern: value, ok := os.LookupEnv("X")
// Go's LookupEnv returns (string, bool), but V's getenv_opt returns ?string
fn (mut app App) check_and_handle_lookup_env(assign AssignStmt) bool {
	// Only handle when there are exactly 2 LHS values and 1 RHS value
	if assign.lhs.len != 2 || assign.rhs.len != 1 {
		return false
	}
	// Check if RHS is a call to os.LookupEnv
	if assign.rhs[0] !is CallExpr {
		return false
	}
	call := assign.rhs[0] as CallExpr
	if call.fun !is SelectorExpr {
		return false
	}
	sel := call.fun as SelectorExpr
	if sel.x !is Ident {
		return false
	}
	mod_name := (sel.x as Ident).name
	fn_name := sel.sel.name
	if mod_name != 'os' || fn_name != 'LookupEnv' {
		return false
	}

	// Get the ok variable name (second LHS)
	mut ok_name := '_'
	if assign.lhs[1] is Ident {
		go_ok_name := (assign.lhs[1] as Ident).name
		ok_name = app.go2v_ident(go_ok_name)
		if ok_name != '_' {
			if ok_name in app.cur_fn_names {
				ok_name = app.unique_name_anti_shadow(ok_name, true)
				app.name_mapping[go_ok_name] = ok_name
			}
			app.cur_fn_names[ok_name] = true
		}
	}

	// Get the val variable name (first LHS)
	mut val_name := '_'
	if assign.lhs[0] is Ident {
		go_val_name := (assign.lhs[0] as Ident).name
		val_name = app.go2v_ident(go_val_name)
		if val_name != '_' {
			if val_name in app.cur_fn_names {
				val_name = app.unique_name_anti_shadow(val_name, true)
				app.name_mapping[go_val_name] = val_name
			}
			app.cur_fn_names[val_name] = true
		}
	}

	// Generate V code for getenv_opt
	// First, get the option value
	tmp_name := if val_name != '_' { val_name + '_opt' } else { 'env_opt_tmp' }
	app.gen('${tmp_name} := os.getenv_opt(')
	if call.args.len > 0 {
		app.expr(call.args[0])
	}
	app.genln(')')

	// Generate the ok check
	if ok_name != '_' {
		app.genln('${ok_name} := ${tmp_name} != none')
	}

	// Generate the value extraction if needed
	if val_name != '_' {
		app.genln("${val_name} := ${tmp_name} or { '' }")
	}

	return true
}

// Check and handle type assertion with comma-ok pattern: val, ok := x.(Type)
fn (mut app App) check_and_handle_type_assertion(assign AssignStmt) bool {
	// Only handle when there are exactly 2 LHS values and 1 RHS value
	if assign.lhs.len != 2 || assign.rhs.len != 1 {
		return false
	}
	// Check if RHS is a type assertion
	if assign.rhs[0] !is TypeAssertExpr {
		return false
	}
	ta := assign.rhs[0] as TypeAssertExpr

	// Get the ok variable name (second LHS)
	mut ok_name := '_'
	if assign.lhs[1] is Ident {
		go_ok_name := (assign.lhs[1] as Ident).name
		ok_name = app.go2v_ident(go_ok_name)
		if ok_name != '_' {
			// Handle shadowing
			if ok_name in app.cur_fn_names {
				ok_name = app.unique_name_anti_shadow(ok_name, true)
				app.name_mapping[go_ok_name] = ok_name
			}
			app.cur_fn_names[ok_name] = true
		}
	}

	// Get the val variable name (first LHS)
	mut val_name := '_'
	if assign.lhs[0] is Ident {
		go_val_name := (assign.lhs[0] as Ident).name
		val_name = app.go2v_ident(go_val_name)
		if val_name != '_' {
			// Handle shadowing
			if val_name in app.cur_fn_names {
				val_name = app.unique_name_anti_shadow(val_name, true)
				app.name_mapping[go_val_name] = val_name
			}
			app.cur_fn_names[val_name] = true
		}
	}

	// Generate the 'is' check for the ok variable
	if ok_name != '_' {
		app.gen('mut ${ok_name} := ')
		app.expr(ta.x)
		app.gen(' is ')
		app.typ(ta.typ)
		app.genln('')
	}

	// If val is not discarded, generate the type cast
	if val_name != '_' {
		app.gen('mut ${val_name} := ')
		app.expr(ta.x)
		app.gen(' as ')
		app.typ(ta.typ)
		app.genln('')
	}

	return true
}

// Check and handle map lookup with comma-ok pattern: value, ok := myMap[key]
// Go: value, ok := m[key] => V: ok := key in m; value := m[key]
fn (mut app App) check_and_handle_map_lookup_ok(assign AssignStmt) bool {
	// Only handle when there are exactly 2 LHS values and 1 RHS value
	if assign.lhs.len != 2 || assign.rhs.len != 1 {
		return false
	}
	// Check if RHS is an IndexExpr (map lookup)
	if assign.rhs[0] !is IndexExpr {
		return false
	}
	idx := assign.rhs[0] as IndexExpr

	// Get the ok variable name (second LHS)
	mut ok_name := '_'
	if assign.lhs[1] is Ident {
		go_ok_name := (assign.lhs[1] as Ident).name
		ok_name = app.go2v_ident(go_ok_name)
		if ok_name != '_' {
			if ok_name in app.cur_fn_names {
				ok_name = app.unique_name_anti_shadow(ok_name, true)
				app.name_mapping[go_ok_name] = ok_name
			}
			app.cur_fn_names[ok_name] = true
		}
	}

	// Get the val variable name (first LHS)
	mut val_name := '_'
	if assign.lhs[0] is Ident {
		go_val_name := (assign.lhs[0] as Ident).name
		val_name = app.go2v_ident(go_val_name)
		if val_name != '_' {
			if val_name in app.cur_fn_names {
				val_name = app.unique_name_anti_shadow(val_name, true)
				app.name_mapping[go_val_name] = val_name
			}
			app.cur_fn_names[val_name] = true
		}
	}

	// Generate the 'in' check for the ok variable
	if ok_name != '_' {
		app.gen('${ok_name} := ')
		app.expr(idx.index)
		app.gen(' in ')
		app.expr(idx.x)
		app.genln('')
	}

	// Generate the value extraction if needed
	if val_name != '_' {
		app.gen('${val_name} := ')
		app.expr(idx.x)
		app.gen('[')
		app.expr(idx.index)
		app.genln(']')
	}

	return true
}

// Check and handle channel receive with comma-ok pattern: value, ok := <-ch
// Go: value, ok := <-ch => V: value_opt := <-ch; ok := value_opt != none; value := value_opt or { default }
fn (mut app App) check_and_handle_chan_recv_ok(assign AssignStmt) bool {
	// Only handle when there are exactly 2 LHS values and 1 RHS value
	if assign.lhs.len != 2 || assign.rhs.len != 1 {
		return false
	}
	// Check if RHS is a UnaryExpr with <- operator (channel receive)
	if assign.rhs[0] !is UnaryExpr {
		return false
	}
	u := assign.rhs[0] as UnaryExpr
	if u.op != '<-' {
		return false
	}

	// Get the ok variable name (second LHS)
	mut ok_name := '_'
	if assign.lhs[1] is Ident {
		go_ok_name := (assign.lhs[1] as Ident).name
		ok_name = app.go2v_ident(go_ok_name)
		if ok_name != '_' {
			if ok_name in app.cur_fn_names {
				ok_name = app.unique_name_anti_shadow(ok_name, true)
				app.name_mapping[go_ok_name] = ok_name
			}
			app.cur_fn_names[ok_name] = true
		}
	}

	// Get the val variable name (first LHS)
	mut val_name := '_'
	if assign.lhs[0] is Ident {
		go_val_name := (assign.lhs[0] as Ident).name
		val_name = app.go2v_ident(go_val_name)
		if val_name != '_' {
			if val_name in app.cur_fn_names {
				val_name = app.unique_name_anti_shadow(val_name, true)
				app.name_mapping[go_val_name] = val_name
			}
			app.cur_fn_names[val_name] = true
		}
	}

	// Generate the channel receive to a temporary option variable
	tmp_name := if val_name != '_' { val_name + '_opt' } else { 'chan_opt_tmp' }
	app.gen('${tmp_name} := <-')
	app.expr(u.x)
	app.genln('')

	// Generate the ok check
	if ok_name != '_' {
		app.genln('${ok_name} := ${tmp_name} != none')
	}

	// Generate the value extraction if needed (with default value of 0)
	if val_name != '_' {
		app.genln('${val_name} := ${tmp_name} or { 0 }')
	}

	return true
}

// Functions that return (value, error) in Go and need Result handling in V
const result_returning_funcs = {
	'strconv.Atoi':       true
	'strconv.ParseInt':   true
	'strconv.ParseUint':  true
	'strconv.ParseFloat': true
	'strconv.ParseBool':  true
}

// Check and handle functions that return (value, error) like strconv.Atoi
// Go: value, err := strconv.Atoi("123") => V: value := strconv.atoi('123') or { 0 }; err_ok := true/false
fn (mut app App) check_and_handle_result_pattern(assign AssignStmt) bool {
	// Only handle when there are exactly 2 LHS values and 1 RHS value
	if assign.lhs.len != 2 || assign.rhs.len != 1 {
		return false
	}
	// Check if RHS is a CallExpr
	if assign.rhs[0] !is CallExpr {
		return false
	}
	call := assign.rhs[0] as CallExpr
	if call.fun !is SelectorExpr {
		return false
	}
	sel := call.fun as SelectorExpr
	if sel.x !is Ident {
		return false
	}

	// Get the module and function name
	mod_name := (sel.x as Ident).name
	fn_name := sel.sel.name
	full_name := '${mod_name}.${fn_name}'

	// Check if this is a known result-returning function
	if full_name !in result_returning_funcs {
		return false
	}

	// Get the err variable name (second LHS)
	mut err_name := '_'
	if assign.lhs[1] is Ident {
		go_err_name := (assign.lhs[1] as Ident).name
		err_name = app.go2v_ident(go_err_name)
		if err_name != '_' {
			if err_name in app.cur_fn_names {
				err_name = app.unique_name_anti_shadow(err_name, true)
				app.name_mapping[go_err_name] = err_name
			}
			app.cur_fn_names[err_name] = true
		}
	}

	// Get the val variable name (first LHS)
	mut val_name := '_'
	if assign.lhs[0] is Ident {
		go_val_name := (assign.lhs[0] as Ident).name
		val_name = app.go2v_ident(go_val_name)
		if val_name != '_' {
			if val_name in app.cur_fn_names {
				val_name = app.unique_name_anti_shadow(val_name, true)
				app.name_mapping[go_val_name] = val_name
			}
			app.cur_fn_names[val_name] = true
		}
	}

	// Generate the value with error handling using 'or' block
	// First, create a temporary to track success/failure
	err_ok_name := if err_name != '_' { err_name + '_ok' } else { '' }
	if err_ok_name != '' {
		app.genln('mut ${err_ok_name} := true')
	}

	if val_name != '_' {
		app.gen('${val_name} := ${mod_name}.${app.go2v_ident(fn_name)}(')
		for i, arg in call.args {
			if i > 0 {
				app.gen(', ')
			}
			app.expr(arg)
		}
		if err_ok_name != '' {
			app.genln(') or { ${err_ok_name} = false; 0 }')
		} else {
			app.genln(') or { 0 }')
		}
	}

	// If err variable is used, map it to a boolean for nil checks
	// Go's 'if err == nil' becomes 'if err == none' in V
	if err_name != '_' {
		// Create a none-able error value that's none when successful
		app.genln('${err_name} := if ${err_ok_name} { none } else { error("conversion failed") }')
		// Track this as an error variable so nil comparisons use 'none'
		app.error_vars[err_name] = true
	}

	return true
}
