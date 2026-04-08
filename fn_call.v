// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) call_expr(call CallExpr) {
	mut fn_name := ''
	mut is_println := false

	// fmt.Println => println
	fun := call.fun

	// Extract module-qualified composite literals to temp vars (V parser workaround)
	// Only do this when at statement level (safe to emit additional statements)
	mut temp_var_names := map[int]string{}
	if app.at_stmt_level {
		for i, arg in call.args {
			if app.needs_temp_var(arg) {
				temp_name := 'go2v_tmp_${app.temp_var_count}'
				app.temp_var_count++
				app.gen('${temp_name} := ')
				// Temporarily disable at_stmt_level for nested expressions
				was_at_stmt := app.at_stmt_level
				app.at_stmt_level = false
				app.expr(arg)
				app.at_stmt_level = was_at_stmt
				app.genln('')
				temp_var_names[i] = temp_name
			}
		}
		// After extracting, we're no longer at top statement level for the actual call
		app.at_stmt_level = false
	}

	// Handle IIFE (Immediately Invoked Function Expression)
	// Go: func() { ... }()  or  (func() { ... })()  =>  V: { ... }
	// V doesn't support IIFE syntax, so convert to a block for simple cases
	// But not for go statements - those need the function literal syntax
	if call.args.len == 0 && !app.in_go_stmt {
		mut func_lit := FuncLit{}
		mut is_iife := false
		if fun is FuncLit {
			func_lit = fun
			is_iife = true
		} else if fun is ParenExpr {
			if fun.x is FuncLit {
				func_lit = fun.x
				is_iife = true
			}
		}
		if is_iife && func_lit.typ.results.list.len == 0 {
			app.block_stmt(func_lit.body)
			return
		}
	}

	// Handle type cast: (int)(x) => isize(x)
	if fun is ParenExpr {
		inner := fun.x
		if inner is Ident {
			type_name := inner.name
			v_type := go2v_type(type_name)
			if v_type != type_name {
				// It's a type conversion like (int)(x)
				app.gen(v_type)
				app.gen('(')
				if call.args.len > 0 {
					app.expr(call.args[0])
				}
				app.gen(')')
				return
			}
		}
	}

	if fun is SelectorExpr {
		if fun.sel.name == 'String' && fun.x is CallExpr {
			app.expr(fun.x)
			app.gen('.str()')
			return
		} else if fun.x is Ident {
			if fun.x.name == 'fmt' && fun.sel.name in ['Println', 'Print'] {
				fn_name = fun.sel.name.to_lower()
				is_println = true
			} else if fun.sel.name == 'len' {
				app.genln('LEN')
			} else {
				// mod.fn_call() is handled lower
			}
		}
	} else if fun is Ident {
		if fun.name in ['len', 'cap'] {
			app.expr(call.args[0])
			app.gen('.')
			app.gen(fun.name)
			return
		} else if fun.name == 'new' {
			// new(Foo) => &Foo{}
			app.gen('&')
			saved_force_upper := app.force_upper
			app.force_upper = true
			app.expr(call.args[0])
			app.force_upper = saved_force_upper
			app.gen('{}')
			return
		} else if fun.name == 'delete' {
			arg0 := call.args[0]
			match arg0 {
				Ident {
					app.gen('${arg0.name}')
				}
				SelectorExpr {
					app.expr(arg0)
				}
				else {
					app.gen('// UNHANDLED delete type')
				}
			}
			app.gen('.${fun.name}(')
			app.expr(call.args[1])
			app.genln(')')
			return
		} else if fun.name == 'string' {
			app.expr(call.args[0])
			app.genln('.str()')
			return
		} else if fun.name == 'append' {
			// Handle Go's append() used as an expression (e.g., in return statements)
			// append(slice, elem1, elem2, ...) => slice + [elem1, elem2, ...]
			// append(slice, other...) => slice + other
			if call.args.len >= 2 {
				app.expr(call.args[0])
				// Check if last arg is Ellipsis (spread operator: other...)
				last_arg := call.args[call.args.len - 1]
				if last_arg is Ellipsis {
					// append(slice, other...) => slice + other
					app.gen(' + ')
					// The Ellipsis wraps the actual value, but we need the elt
					// For now, just output the expression which should handle it
					app.expr(last_arg)
				} else {
					// append(slice, elem1, elem2, ...) => slice + [elem1, elem2, ...]
					app.gen(' + [')
					for i, arg in call.args[1..] {
						if i > 0 {
							app.gen(', ')
						}
						app.expr(arg)
					}
					app.gen(']')
				}
			} else if call.args.len == 1 {
				// append(slice) => slice (no-op)
				app.expr(call.args[0])
			}
			return
		} else if call.args.len == 1 && fun.name in app.struct_or_alias {
			// Type alias conversion, e.g. B(x) => BB(x)
			app.force_upper = true
			app.gen(app.go2v_ident(fun.name))
			app.gen('(')
			app.expr(call.args[0])
			app.gen(')')
			return
		} else if fun.name != go2v_type(fun.name) {
			app.gen(go2v_type(fun.name))
			app.gen('(')
			app.expr(call.args[0])
			app.gen(')')
			return
		} else if fun.name == 'make' {
			app.make_call(call)
			return
		} else if fun.name in ['print', 'println'] {
			fn_name = fun.name
			is_println = true
		}
	}

	// []byte(str) => str.bytes()
	// []rune(str) => str.runes
	if fun is ArrayType {
		elt := fun.elt
		if elt is Ident && elt.name == 'byte' {
			x := call.args[0]
			// TODO not every expr/type can be handled like this?
			// if x is BasicLit {
			app.expr(x)
			app.gen('.bytes()')
			return
		}
		if elt is Ident && elt.name == 'rune' {
			x := call.args[0]
			app.expr(x)
			app.gen('.runes')
			return
		}
	}

	if !is_println {
		if fun is SelectorExpr {
			// Custom selector expr fn for lower case
			app.selector_expr_fn_call(call, fun) // fun)
		} else {
			app.expr(fun)
		}
	}

	// Check if call was fully handled (e.g., atomic operations)
	if app.skip_call_parens {
		app.skip_call_parens = false
		return
	}

	// Can be empty if not println
	fn_name = app.go2v_ident(fn_name)

	app.gen('${fn_name}(') // fn_name is empty unless print

	if call.args.len > 0 {
		if is_println {
			// In V println can only accept one argument, so convert multiple arguments into a single string
			// with concatenation:
			// `fmt.Println(a, b)` => `println('${a} ${b}')`
			more_than_one := call.args.len > 1
			if more_than_one {
				app.gen("'")
			}
			for i, arg in call.args {
				if i > 0 {
					app.gen(' ')
				}
				if arg is BasicLit {
					if !more_than_one {
						app.basic_lit(arg)
					} else {
						// For strings, strip quotes; for other literals (int, float, bool), use as-is
						if arg.kind == 'STRING' {
							// Escape single quotes since we're building a single-quoted V string
							content := arg.value[1..arg.value.len - 1].replace("'", r"\'")
							app.gen(content)
						} else {
							app.gen(arg.value)
						}
					}
				} else if arg is BinaryExpr {
					app.expr(arg)
				} else if arg is Ident && arg.name in ['true', 'false'] {
					// Boolean literals should be embedded directly
					app.gen(arg.name)
				} else {
					if more_than_one {
						app.gen('\${')
					}
					app.expr(arg)
					if more_than_one {
						app.gen('}')
					}
				}
			}
			if more_than_one {
				app.gen("'")
			}
		} else if fun is SelectorExpr {
			mut count := 0
			for idx, arg in call.args {
				if idx == 0 && fun.x is Ident && fun.x.name == 'strings' {
					continue
				}
				if count > 0 {
					app.gen(', ')
				}
				// Add mut for first arg if needed (e.g., binary.PutUint* functions)
				if idx == 0 && app.first_arg_needs_mut {
					app.gen('mut ')
					app.first_arg_needs_mut = false
				}
				// Use temp var if we extracted it earlier (from this call or pre-extracted in assign)
				if idx in temp_var_names {
					app.gen(temp_var_names[idx])
				} else if '${idx}' in app.call_arg_temp_vars {
					app.gen(app.call_arg_temp_vars['${idx}'])
				} else {
					app.expr(arg)
				}
				count++
			}
		} else if fun is Ident {
			for idx, arg in call.args {
				if idx > 0 {
					app.gen(', ')
				}
				// Use temp var if we extracted it earlier (from this call or pre-extracted in assign)
				if idx in temp_var_names {
					app.gen(temp_var_names[idx])
				} else if '${idx}' in app.call_arg_temp_vars {
					app.gen(app.call_arg_temp_vars['${idx}'])
				} else {
					app.expr(arg)
				}
			}
		}
	}
	app.gen(')')
	// Add extra closing paren for wrapped calls like print(strconv.v_sprintf(...))
	if app.fmt_needs_closing_paren {
		app.gen(')')
		app.fmt_needs_closing_paren = false
	}
}

fn (mut app App) selector_expr_fn_call(call CallExpr, sel SelectorExpr) {
	if sel.x is Ident {
		if sel.x.name in modules_needing_call_translation {
			app.handle_nonexistent_module_call(sel, sel.x.name, sel.sel.name, call)
			return
		}
	}
	// Handle encoding/binary endianness functions:
	// binary.LittleEndian.Uint32(...) -> binary.little_endian_u32(...)
	// binary.BigEndian.Uint32(...) -> binary.big_endian_u32(...)
	// binary.LittleEndian.PutUint32(...) -> binary.little_endian_put_u32(mut ...)
	// Note: V import is `import encoding.binary` but usage is `binary.xxx`
	if sel.x is SelectorExpr {
		outer_sel := sel.x as SelectorExpr
		if outer_sel.x is Ident {
			mod_name := (outer_sel.x as Ident).name
			if mod_name == 'binary' {
				endianness := outer_sel.sel.name.camel_to_snake() // LittleEndian -> little_endian
				fn_name := sel.sel.name.camel_to_snake() // Uint32 -> uint32, PutUint32 -> put_uint32
				// V uses little_endian_u32 not little_endian_uint32
				v_fn := fn_name.replace('uint', 'u').replace('int', 'i')
				app.gen('binary.${endianness}_${v_fn}')
				// Put* functions need mut for first argument
				if fn_name.starts_with('put_') {
					app.first_arg_needs_mut = true
				}
				return
			}
		}
	}
	// Handle .String() method - only convert to .str() if it's a no-arg call (Stringer interface)
	// If it has arguments, it's a custom method and should become .string_()
	app.selector_xxx_fn_call(sel, call.args.len)
}

fn (mut app App) selector_xxx_fn_call(sel SelectorExpr, arg_count int) {
	app.expr(sel.x)
	app.gen('.')
	mut sel_name := sel.sel.name
	// Only translate String() -> str() for no-argument calls (Stringer interface)
	// Custom String(args...) methods should become string_() to avoid conflict with V's .str()
	if sel.sel.name == 'String' {
		if arg_count == 0 {
			sel_name = 'str'
		} else {
			sel_name = 'string_' // snake_case + underscore to avoid V's reserved .str()
		}
	}
	app.gen(app.go2v_ident(sel_name))
}

fn (mut app App) selector_xxx(sel SelectorExpr) {
	app.expr(sel.x)
	app.gen('.')
	mut sel_name := sel.sel.name //.to_lower()
	if sel.sel.name == 'String' {
		sel_name = 'str'
	}
	app.gen(app.go2v_ident(sel_name))
}

fn (mut app App) make_call(call CallExpr) {
	app.force_upper = true
	app.expr(call.args[0])
	if call.args[0] is ArrayType {
		// len only
		if call.args.len == 2 {
			app.gen('{len: ')
			app.expr(call.args[1])
			app.gen('}')
		}
		// cap + len
		else if call.args.len == 3 {
			app.gen('{len: ')
			app.expr(call.args[1])
			app.gen(', cap: ')
			app.expr(call.args[2])
			app.gen('}')
		}
	} else if call.args[0] is SelectorExpr {
		// Type alias for slice - vfmt breaks len:/cap: syntax for type aliases
		// Just create empty instance; capacity optimization is lost but code compiles
		app.gen('{}')
	} else if call.args[0] is MapType {
		app.gen('{}')
	} else if call.args[0] is Ident {
		// Type alias without module prefix - same issue as SelectorExpr
		app.gen('{}')
	} else {
		app.gen('{}')
	}
}
