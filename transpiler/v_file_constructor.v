module transpiler

fn v_file_constructor(v_ast VAST) string {
	mut v := v_ast
	v.handle_module()
	v.handle_imports()
	v.handle_types()
	v.handle_structs()
	v.handle_consts()
	v.handle_enums()
	v.handle_functions()

	// remove last newline
	v.out.cut_last(1)

	return v.out.str()
}

fn (mut v VAST) handle_module() {
	v.out.writeln('module ${v.@module}')
}

fn (mut v VAST) handle_imports() {
	for imp in v.imports {
		// remove useless `fmt` import
		if !(imp == 'fmt' && v.fmt_import_count == v.fmt_supported_fn_count) {
			v.out.writeln('import $imp')
		}
	}
}

fn (mut v VAST) handle_types() {
	for name, typ in v.types {
		v.out.writeln('type $name = $typ')
	}
}

fn (mut v VAST) handle_structs() {
	for strct in v.structs {
		v.out.write_string('struct $strct.name {')
		for field, typ in strct.fields {
			v.out.writeln('$field $typ')
		}
		v.out.writeln('}')
	}
}

fn (mut v VAST) handle_consts() {
	if v.consts.len != 0 {
		if v.consts.len == 1 {
			key := v.consts.keys()[0]
			v.out.writeln('const $key = ${v.consts[key]}')
		} else {
			v.out.writeln('const (')
			for key, val in v.consts {
				v.out.writeln('$key = $val')
			}
			v.out.writeln(')')
		}
	}
}

fn (mut v VAST) handle_enums() {
	for enm in v.enums {
		v.out.writeln('enum $enm.name {')
		for name, val in enm.fields {
			if val.len == 0 {
				v.out.writeln(name)
			} else {
				v.out.writeln('$name = $val')
			}
		}
		v.out.writeln('}')
	}
}

fn (mut v VAST) handle_functions() {
	for func in v.functions {
		// comment
		v.out.writeln(func.comment)
		// public/private
		if func.public {
			v.out.write_string('pub ')
		}
		// keyword
		v.out.write_string('fn ')
		// method
		if func.method.len != 0 {
			v.out.write_string('(${func.method[0]} ${func.method[1]}) ')
		}
		// name
		v.out.write_string('${func.name}(')
		// arguments
		for name, @type in func.args {
			v.out.write_string('$name ${@type}, ')
		}
		v.out.write_string(')')
		// return value(s)

		if func.ret_vals.len > 0 {
			v.out.write_string(' (')
			mut len := func.ret_vals.len
			for i, val in func.ret_vals {
				// TODO: useless after https://github.com/vlang/v/issues/13592 gets fixed
				if i != len - 1 {
					v.out.write_string('$val, ')
				} else {
					v.out.write_string('$val')
				}
			}
			v.out.write_string(')')
		}
		// body
		v.out.write_string(' {')
		v.handle_body(func.body)
		v.out.writeln('}')
	}
}

fn (mut v VAST) handle_body(body []Statement) {
	for stmt in body {
		v.handle_stmt(stmt, false)
	}
}

fn (mut v VAST) handle_stmt(stmt Statement, is_value bool) {
	match stmt {
		VariableStmt {
			has_explicit_type := stmt.@type.len > 0
			stop := stmt.names.len - 1

			if stmt.mutable && stmt.middle == ':=' {
				v.out.write_string('mut ')
			}

			// name(s)
			for i, name in stmt.names {
				v.out.write_string(name)
				v.out.write_string(if i != stop { ',' } else { '' })
			}

			// eg: `:=`, `+=`, `=`
			v.out.write_string(stmt.middle)

			// value(s)
			for i, value in stmt.values {
				// explicit type
				if has_explicit_type {
					v.out.write_string('${stmt.@type}(')
				}
				v.handle_stmt(value, true)
				if has_explicit_type {
					v.out.write_rune(`)`)
				}
				v.out.write_string(if i != stop { ',' } else { '' })
			}
		}
		IncDecStmt {
			v.out.write_string('$stmt.var$stmt.inc')
		}
		CallStmt {
			v.out.write_string('${stmt.namespaces}(')
			for i, arg in stmt.args {
				v.handle_stmt(arg, true)
				// TODO: useless after https://github.com/vlang/v/issues/13592 gets fixed
				v.out.write_string(if i != stmt.args.len - 1 { ',' } else { '' })
			}
			v.out.write_rune(`)`)
		}
		IfStmt {
			for i, branch in stmt.branchs {
				if i != 0 {
					v.out.write_string('else ')
				}
				if branch.condition != ' ' {
					v.out.write_string('if $branch.condition ')
				}
				v.out.write_rune(`{`)
				v.handle_body(branch.body)
				v.out.write_rune(`}`)
			}
		}
		ForStmt {
			v.out.write_string('for ')
			// check if stmt.init or stmt.post aren't null
			if stmt.init.names.len > 0 || stmt.post.type_name() != 'unknown transpiler.Statement' {
				// c-style for
				v.handle_stmt(stmt.init, true)
				v.out.write_string(';$stmt.condition;')
				v.handle_stmt(stmt.post, true)
			} else {
				// while
				v.out.write_string(stmt.condition)
			}
			// for bare loops no need to write anything
			v.out.write_rune(`{`)
			v.handle_body(stmt.body)
			v.out.write_rune(`}`)
		}
		ForInStmt {
			if stmt.idx.len > 0 || stmt.element.len > 0 {
				v.out.write_string('for $stmt.idx, $stmt.element in ')
			} else {
				v.out.write_string('for _ in ')
			}
			v.handle_stmt(stmt.variable, true)
			v.out.write_rune(`{`)
			v.handle_body(stmt.body)
			v.out.write_rune(`}`)
		}
		BranchStmt {
			v.out.write_string(stmt.name)
		}
		ArrayStmt {
			is_empty := stmt.values.len < 1
			is_fixed_size := stmt.len.len > 0

			v.out.write_rune(`[`)

			if is_empty {
				if is_fixed_size {
					v.out.write_string(stmt.len)
				}
				v.out.write_string(']${stmt.@type}{}')
			} else {
				for el in stmt.values {
					v.out.write_string('$el, ')
				}

				mut i := stmt.values.len
				if is_fixed_size && i < stmt.len.int() {
					default_val := match stmt.@type {
						'string' { "''" }
						'int' { '0' }
						'bool' { 'false' }
						else { '${stmt.@type}{}' }
					}

					mut is_first := true
					for i != stmt.len.int() {
						if is_first {
							is_first = false
							v.out.write_string('$default_val')
						} else {
							v.out.write_string(', $default_val')
						}
						i++
					}
				}

				v.out.write_rune(`]`)
				if is_fixed_size {
					v.out.write_rune(`!`)
				}
			}
		}
		BasicValueStmt {
			v.out.write_string(stmt.value)
		}
		SliceStmt {
			v.out.write_string('$stmt.value[${stmt.low}..$stmt.high]')
		}
		ReturnStmt {
			v.out.write_string('return ')
			for el in stmt.values {
				v.handle_stmt(el, true)
				v.out.write_rune(`,`)
			}
		}
		DeferStmt {
			v.out.write_string('defer {')
			v.handle_stmt(stmt.value, true)
			v.out.write_rune(`}`)
		}
		IndexStmt {
			v.out.write_string(stmt.value)
		}
		MatchStmt {
			v.out.write_string('match ')
			v.handle_stmt(stmt.value, true)
			v.out.write_rune(`{`)
			for case in stmt.cases {
				if case.values.len > 0 {
					for i, value in case.values {
						if i > 0 {
							v.out.write_rune(`,`)
						}
						v.handle_stmt(value, true)
					}
				} else {
					v.out.write_string('else')
				}
				v.out.write_rune(`{`)
				v.handle_body(case.body)
				v.out.write_rune(`}`)
			}
			v.out.write_rune(`}`)
		}
		StructStmt {
			v.out.write_string('$stmt.name{')
			for field in stmt.fields {
				v.handle_stmt(field, true)
			}
			v.out.write_rune(`}`)
		}
		KeyValStmt {
			v.out.write_string('$stmt.key:')
			v.handle_stmt(stmt.value, true)
		}
		NotImplYetStmt {}
	}

	if !is_value {
		v.out.write_rune(`\n`)
	}
}
