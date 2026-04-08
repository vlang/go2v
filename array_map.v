// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

// infer_interface_elt_type returns the V type name for a []interface{} element,
// or '' if the type cannot be determined statically.
fn (app App) infer_interface_elt_type(elt Expr) string {
	match elt {
		BasicLit {
			match elt.kind {
				'FLOAT' { return 'f32' }
				'STRING' { return 'string' }
				'INT' { return 'isize' }
				'CHAR' { return 'rune' }
				else { return '' }
			}
		}
		CallExpr {
			// make(chan T) => 'chan V_T' (the full channel type with element)
			if elt.fun is Ident
				&& (elt.fun as Ident).name == 'make' && elt.args.len > 0 && elt.args[0] is ChanType {
				chan_t := elt.args[0] as ChanType
				if chan_t.value is Ident {
					v_elt_type := go2v_type((chan_t.value as Ident).name)
					return 'chan ${v_elt_type}'
				}
				return 'chan'
			}
			return ''
		}
		UnaryExpr {
			return app.infer_interface_elt_type(elt.x)
		}
		else {
			return ''
		}
	}
}

// get_or_create_sum_type returns the name of a sum type for the given elem types,
// creating and registering the declaration if it does not already exist.
fn (mut app App) get_or_create_sum_type(elem_types []string) string {
	key := elem_types.join('|')
	if key in app.pending_sum_type_names {
		return app.pending_sum_type_names[key]
	}
	mut name := 'Any'
	if app.pending_sum_types.len > 0 {
		name = 'Any${app.pending_sum_types.len + 1}'
	}
	app.pending_sum_type_names[key] = name
	decl := 'type ${name} = ${elem_types.join(' | ')}\n'
	app.pending_sum_types << decl
	return name
}

// gen_interface_elt_as_sum_type emits a single element of a []interface{} literal
// translated to use a V sum type.  The first element is wrapped as SumType(val)
// so V can infer the array's element type; subsequent elements are emitted as-is.
// make(chan T) is special-cased to emit `chan V_T{}` (zero-value channel).
fn (mut app App) gen_interface_elt_as_sum_type(elt Expr, sum_type_name string, is_first bool) {
	match elt {
		BasicLit {
			if is_first {
				app.gen('${sum_type_name}(')
				app.basic_lit(elt)
				app.gen(')')
			} else {
				app.basic_lit(elt)
			}
		}
		CallExpr {
			// make(chan T) => emit `chan V_T{}` (zero-value channel, not a make() call)
			if elt.fun is Ident
				&& (elt.fun as Ident).name == 'make' && elt.args.len > 0 && elt.args[0] is ChanType {
				app.chan_type(elt.args[0] as ChanType)
				app.gen('{}')
				return
			}
			if is_first {
				app.gen('${sum_type_name}(')
				app.call_expr(elt)
				app.gen(')')
			} else {
				app.call_expr(elt)
			}
		}
		else {
			if is_first {
				app.gen('${sum_type_name}(')
				app.expr(elt)
				app.gen(')')
			} else {
				app.expr(elt)
			}
		}
	}
}

fn (mut app App) array_init(c CompositeLit) {
	typ := c.typ
	match typ {
		ArrayType {
			mut have_len := false
			mut len_val := ''
			// Any non-InvalidExpr length means fixed-size array
			mut is_fixed := typ.len !is InvalidExpr
			if typ.len is BasicLit {
				have_len = typ.len.value != ''
				len_val = typ.len.value
			}
			mut elt_name := ''
			mut elt_is_selector := false
			mut elt_is_ident := false
			mut elt_is_interface := false
			mut sum_type_name := ''
			match typ.elt {
				ArrayType {
					// Nested array, e.g., [][]int
					elt_name = ''
				}
				Ident {
					// Get the converted type, capitalize if it's a struct/type name
					type_conv := go2v_type_checked(typ.elt.name)
					if type_conv.is_basic {
						elt_name = type_conv.v_type
					} else {
						// Struct/type names must be capitalized in V
						elt_name = typ.elt.name.capitalize()
					}
					elt_is_ident = true
				}
				SelectorExpr {
					// e.g., []logger.MsgData
					elt_name = ''
					elt_is_selector = true
				}
				StarExpr {
					x := typ.elt.x
					match x {
						Ident {
							elt_name = go2v_type(x.name)
						}
						SelectorExpr {
							// e.g., []*pkg.Type
							elt_name = ''
							elt_is_selector = true
						}
						else {
							app.gen('>> unhandled array type "${x.node_type}"')
						}
					}
				}
				StructType {
					// Inline/anonymous struct as array element
					struct_name := app.generate_inline_struct(typ.elt)
					elt_name = struct_name
					elt_is_ident = true
				}
				InterfaceType {
					// []interface{} - try to infer types and use a sum type; fall back to []string
					if c.elts.len > 0 {
						mut elem_v_types := []string{}
						mut all_types_known := true
						for elt in c.elts {
							t := app.infer_interface_elt_type(elt)
							if t == '' {
								all_types_known = false
								break
							}
							if t !in elem_v_types {
								elem_v_types << t
							}
						}
						if all_types_known && elem_v_types.len > 0 {
							sum_type_name = app.get_or_create_sum_type(elem_v_types)
						} else {
							elt_name = 'string'
							elt_is_interface = true
						}
					} else {
						elt_name = 'string'
						elt_is_interface = true
					}
				}
				else {
					app.gen('>> unhandled array element type "${typ.elt}"')
					return
				}
			}

			// No elements, just `[]bool{}` (specify type)
			app.gen('[')
			if c.elts.len == 0 {
				if have_len {
					app.gen(len_val)
				}
				app.gen(']')
				if elt_is_selector {
					app.force_upper = true
					app.selector_expr(typ.elt as SelectorExpr)
				} else {
					app.gen(elt_name)
				}
				app.gen('{}')
			} else {
				if sum_type_name != '' {
					// Generate array literal using the inferred sum type
					for i, elt in c.elts {
						if i > 0 {
							app.gen(', ')
						}
						app.gen_interface_elt_as_sum_type(elt, sum_type_name, i == 0)
					}
					app.gen(']')
					return
				}
				if elt_is_interface {
					for i, elt in c.elts {
						if i > 0 {
							app.gen(',')
						}
						app.gen(r"'${")
						app.expr(elt)
						app.gen("}'")
					}
					app.gen(']')
					return
				}
				match c.elts[0] {
					BasicLit, BinaryExpr, CallExpr, CompositeLit, Ident, IndexExpr, SelectorExpr,
					StarExpr, UnaryExpr {
						for i, elt in c.elts {
							if i > 0 {
								app.gen(',')
							}
							if elt is CompositeLit && (elt as CompositeLit).typ is InvalidExpr {
								// Array with implicit element type
								// []Type{{Field: value}} => [Type{field: value}]
								// []pkg.Type{{Field: value}} => [pkg.Type{field: value}]
								// [][]int{{1,2,3}} => [[isize(1),2,3]]
								if typ.elt is ArrayType {
									// Nested array - generate array literal with type cast on first element
									comp := elt as CompositeLit
									app.gen('[')
									inner_elt := typ.elt as ArrayType
									mut inner_type_name := ''
									if inner_elt.elt is Ident {
										inner_type_name = go2v_type((inner_elt.elt as Ident).name)
									}
									for j, e in comp.elts {
										if j > 0 {
											app.gen(', ')
										}
										// Add type cast on first element of each inner array
										if j == 0 && inner_type_name != ''
											&& inner_type_name != 'string'
											&& !inner_type_name.starts_with_capital() {
											app.gen('${inner_type_name}(')
											app.expr(e)
											app.gen(')')
										} else {
											app.expr(e)
										}
									}
									app.gen(']')
								} else if elt_is_selector {
									app.force_upper = true
									app.selector_expr(typ.elt as SelectorExpr)
									app.gen('{')
									comp := elt as CompositeLit
									for j, e in comp.elts {
										if j > 0 {
											app.gen(', ')
										}
										app.expr(e)
									}
									app.gen('}')
								} else if elt_is_ident {
									app.force_upper = true
									app.gen(elt_name)
									app.gen('{')
									comp := elt as CompositeLit
									for j, e in comp.elts {
										if j > 0 {
											app.gen(', ')
										}
										app.expr(e)
									}
									app.gen('}')
								} else {
									// Fallback: just output struct literal
									app.gen('{')
									comp := elt as CompositeLit
									for j, e in comp.elts {
										if j > 0 {
											app.gen(', ')
										}
										app.expr(e)
									}
									app.gen('}')
								}
							} else if i == 0 && elt_name != '' && elt_name != 'string'
								&& !elt_name.starts_with_capital() {
								// specify type in the first element
								// [u8(1), 2, 3]
								app.gen('${elt_name}(')
								app.expr(elt)
								app.gen(')')
							} else {
								app.expr(elt)
							}
						}
						if have_len {
							diff := len_val.int() - c.elts.len
							if diff > 0 {
								for _ in 0 .. diff {
									app.gen(',')
									match elt_name {
										'isize', 'usize' { app.gen('0') }
										'string' { app.gen("''") }
										else { app.gen('unknown element type??') }
									}
								}
							}
						}
						app.gen(']')
					}
					KeyValueExpr {
						// For sparse array initialization, compute max key + 1 for length (dynamic arrays only)
						mut max_key := 0
						for elt in c.elts {
							kv := elt as KeyValueExpr
							if kv.key is BasicLit {
								key_lit := kv.key as BasicLit
								mut key_val := 0
								if key_lit.value.starts_with('0x') {
									key_val = int(key_lit.value[2..].parse_int(16, 32) or { 0 })
								} else {
									key_val = key_lit.value.int()
								}
								if key_val > max_key {
									max_key = key_val
								}
							}
						}
						// For Ellipsis [...], output computed size; otherwise output the length expression
						if typ.len is Ellipsis {
							app.gen('${max_key + 1}')
						} else if typ.len !is InvalidExpr {
							app.expr(typ.len)
						}
						// For fixed arrays, don't include len: attribute; for dynamic arrays, include it
						if is_fixed {
							app.gen(']${elt_name}{init: match index {')
						} else {
							app.gen(']${elt_name}{len: ${max_key + 1}, init: match index {')
						}
						for elt in c.elts {
							app.expr((elt as KeyValueExpr).key)
							app.gen(' { ')
							kv_value := (elt as KeyValueExpr).value
							// Check if value is a CompositeLit with implicit type
							if kv_value is CompositeLit
								&& (kv_value as CompositeLit).typ is InvalidExpr {
								// Add the element type name before the struct literal
								if elt_is_ident {
									app.force_upper = true
									app.gen(app.go2v_ident((typ.elt as Ident).name))
								} else if elt_is_selector {
									app.force_upper = true
									app.selector_expr(typ.elt as SelectorExpr)
								}
								app.gen('{')
								comp := kv_value as CompositeLit
								for j, e in comp.elts {
									if j > 0 {
										app.gen(', ')
									}
									// Handle KeyValueExpr explicitly to ensure lowercase field names
									if e is KeyValueExpr {
										kve := e as KeyValueExpr
										if kve.key is Ident {
											app.gen(app.go2v_ident((kve.key as Ident).name))
											app.gen(': ')
										} else {
											app.expr(kve.key)
											app.gen(': ')
										}
										app.expr(kve.value)
									} else {
										app.expr(e)
									}
								}
								app.gen('}')
							} else {
								app.expr(kv_value)
							}
							app.gen(' }')
						}
						// For else clause, use appropriate default based on element type
						if elt_is_ident && elt_name.starts_with_capital() {
							// Struct type - use empty struct literal
							app.gen(' else { ${elt_name}{} }}}')
						} else {
							app.gen(' else { 0 }}}')
						}
						// Don't add '!' for sparse init - size is already specified via {init:}
						is_fixed = false
					}
					else {
						app.gen('>> unhandled array element type ${c.elts[0]}')
					}
				}
				if is_fixed {
					app.gen('!')
				}
			}
		}
		else {}
	}
}

fn (mut app App) map_init(node CompositeLit) {
	// In V, non-empty map initialization uses { key: value } syntax without the map[K]V prefix
	// Empty maps use map[K]V{}
	if node.elts.len == 0 {
		app.expr(node.typ)
		app.gen('{}')
		return
	}
	// For non-empty maps, just use { ... } syntax
	app.genln('{')
	map_typ := node.typ as MapType
	for elt in node.elts {
		kv := elt as KeyValueExpr
		// Handle key
		if kv.key is Ident {
			app.gen('\t${app.go2v_ident(kv.key.name)}: ')
		} else {
			app.expr(kv.key)
			app.gen(': ')
		}
		// Handle value - check if it's an implicit initialization
		if kv.value is CompositeLit && (kv.value as CompositeLit).typ is InvalidExpr {
			comp := kv.value as CompositeLit
			// Check if map value type is an array - generate array literal
			if map_typ.val is ArrayType {
				arr_typ := map_typ.val as ArrayType
				app.gen('[')
				for i, e in comp.elts {
					if i > 0 {
						app.gen(', ')
					}
					// Handle implicit struct in array
					if e is CompositeLit && (e as CompositeLit).typ is InvalidExpr {
						e_comp := e as CompositeLit
						// Get array element type and prefix the struct literal
						match arr_typ.elt {
							Ident {
								app.force_upper = true
								app.gen(app.go2v_ident(arr_typ.elt.name))
							}
							SelectorExpr {
								app.force_upper = true
								app.selector_expr(arr_typ.elt)
							}
							else {}
						}
						app.gen('{')
						for j, field in e_comp.elts {
							if j > 0 {
								app.gen(', ')
							}
							app.expr(field)
						}
						app.gen('}')
					} else {
						app.expr(e)
					}
				}
				app.gen(']')
			} else if map_typ.val is MapType {
				// Nested map - just generate the map literal (no type prefix for non-empty maps)
				nested_map_typ := map_typ.val as MapType
				app.nested_map_init(comp, nested_map_typ)
			} else {
				// Implicit struct value - need to prefix with map's value type
				app.force_upper = true
				match map_typ.val {
					Ident {
						app.gen(app.go2v_ident(map_typ.val.name))
					}
					SelectorExpr {
						app.selector_expr(map_typ.val)
					}
					StarExpr {
						app.star_expr(map_typ.val)
					}
					else {}
				}
				app.gen('{')
				if comp.elts.len > 0 {
					app.genln('')
				}
				for e in comp.elts {
					app.expr(e)
					app.genln('')
				}
				app.gen('}')
			}
		} else {
			if kv.value is CompositeLit {
				comp := kv.value as CompositeLit
				if comp.typ is StructType {
					st := comp.typ as StructType
					if st.fields.list.len == 0 && comp.elts.len == 0 {
						app.gen('struct{}')
					} else {
						app.expr(kv.value)
					}
				} else {
					app.expr(kv.value)
				}
			} else {
				app.expr(kv.value)
			}
		}
		app.genln('')
	}
	app.gen('}')
}

fn (mut app App) nested_map_init(comp CompositeLit, map_typ MapType) {
	app.genln('{')
	for elt in comp.elts {
		kv := elt as KeyValueExpr
		// Handle key
		if kv.key is Ident {
			app.gen('\t${app.go2v_ident(kv.key.name)}: ')
		} else {
			app.expr(kv.key)
			app.gen(': ')
		}
		// Handle value - check if it's an implicit initialization
		if kv.value is CompositeLit && (kv.value as CompositeLit).typ is InvalidExpr {
			inner_comp := kv.value as CompositeLit
			// Check if map value type is an array - generate array literal
			if map_typ.val is ArrayType {
				arr_typ := map_typ.val as ArrayType
				app.gen('[')
				for i, e in inner_comp.elts {
					if i > 0 {
						app.gen(', ')
					}
					// Handle implicit struct in array
					if e is CompositeLit && (e as CompositeLit).typ is InvalidExpr {
						e_comp := e as CompositeLit
						// Get array element type and prefix the struct literal
						match arr_typ.elt {
							Ident {
								app.force_upper = true
								app.gen(app.go2v_ident(arr_typ.elt.name))
							}
							else {}
						}
						app.gen('{')
						for j, field in e_comp.elts {
							if j > 0 {
								app.gen(', ')
							}
							app.expr(field)
						}
						app.gen('}')
					} else {
						app.expr(e)
					}
				}
				app.gen(']')
			} else {
				app.expr(kv.value)
			}
		} else {
			app.expr(kv.value)
		}
		app.genln('')
	}
	app.gen('}')
}
