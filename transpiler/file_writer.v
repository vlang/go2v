module transpiler

// entry point for the file writing phase
fn file_writer(v_ast VAST) string {
	mut v := v_ast
	v.write_module()
	v.write_imports()
	v.write_consts()
	v.write_sumtypes()
	v.write_enums()
	v.write_structs()
	v.write_functions()

	// remove last newline
	v.out.cut_last(1)

	return v.out.str()
}

// write the module name
fn (mut v VAST) write_module() {
	v.out.writeln('module ${v.@module}')
}

// write the module imports
fn (mut v VAST) write_imports() {
	for @import in v.imports {
		// remove useless `fmt` import
		if !(@import in v.unused_import && !v.unused_import[@import]) {
			v.out.writeln('import ${@import}')
		}
	}
}

// write the constants
fn (mut v VAST) write_consts() {
	if v.consts.len != 0 {
		if v.consts.len == 1 {
			v.out.write_string('const ')
			v.write_stmt(v.consts[0], false)
		} else {
			v.out.writeln('const (')
			for @const in v.consts {
				v.write_stmt(@const, false)
			}
			v.out.writeln(')')
		}
	}
}

// write the sumtypes
fn (mut v VAST) write_sumtypes() {
	for name, typ in v.types {
		v.out.writeln('type $name = $typ')
	}
}

// write the enums
fn (mut v VAST) write_enums() {
	for enm in v.enums {
		v.out.writeln('enum $enm.name {')
		for name, val in enm.fields {
			if val is BasicValueStmt && (val as BasicValueStmt).value.len == 0 {
				v.out.writeln(name)
			} else {
				v.out.writeln('$name = ')
				v.write_stmt(val, true)
			}
		}
		v.out.writeln('}')
	}
}

// write the structs
fn (mut v VAST) write_structs() {
	for strct in v.structs {
		v.out.write_string('struct $strct.name {')
		for embedded_struct in strct.embedded_structs {
			v.out.writeln(embedded_struct)
		}
		if strct.fields.len > 0 {
			v.out.write_string('\nmut:\n')
			for field, typ in strct.fields {
				v.out.write_string('$field ')
				v.write_stmt(typ, true)
				v.out.write_rune(`\n`)
			}
		}
		v.out.writeln('}')
	}
}

// write the functions
fn (mut v VAST) write_functions() {
	for func in v.functions {
		v.write_stmt(func, false)
	}
}

// write the function, if, for... bodies
fn (mut v VAST) write_body(body []Statement) {
	for stmt in body {
		v.write_stmt(stmt, false)
	}
}

// write a statement
fn (mut v VAST) write_stmt(stmt Statement, is_value bool) {
	match stmt {
		FunctionStmt {
			// comment
			if stmt.comment.len > 0 {
				v.out.writeln(stmt.comment)
			}
			// public/private
			if stmt.public {
				v.out.write_string('pub ')
			}
			// keyword
			v.out.write_string('fn ')
			// method
			if stmt.method.len != 0 {
				v.out.write_string('(${stmt.method[0]} ${stmt.method[1]}) ')
			}
			// name
			v.out.write_string('${stmt.name}(')
			// arguments
			// useless after https://github.com/vlang/v/issues/13909 gets fixed
			mut i := 0
			for name, @type in stmt.args {
				if i != stmt.args.len - 1 {
					v.out.write_string('$name ${@type}, ')
				} else {
					v.out.write_string('$name ${@type}')
				}
				i++
			}
			v.out.write_string(')')
			// return value(s)

			if stmt.ret_vals.len > 0 {
				v.out.write_string(' (')
				for j, val in stmt.ret_vals {
					// TODO: useless after https://github.com/vlang/v/issues/13592 gets fixed
					if j != stmt.ret_vals.len - 1 {
						v.out.write_string('$val, ')
					} else {
						v.out.write_string('$val')
					}
				}
				v.out.write_string(')')
			}
			// body
			if !stmt.type_ctx {
				v.out.write_string(' {')
				v.write_body(stmt.body)
				v.out.writeln('}')
			}
		}
		VariableStmt {
			if stmt.names.len > 0 {
				has_explicit_type := stmt.@type.len > 0

				if stmt.mutable && stmt.middle == ':=' {
					v.out.write_string('mut ')
				}

				// name(s)
				for i, name in stmt.names {
					v.out.write_string(name)
					v.out.write_string(if i != stmt.names.len - 1 { ',' } else { '' })
				}

				// eg: `:=`, `+=`, `=`
				v.out.write_string(stmt.middle)

				// value(s)
				if stmt.values.len > 0 {
					for i, value in stmt.values {
						// explicit type
						if has_explicit_type {
							v.out.write_string('${stmt.@type}(')
						}
						v.write_stmt(value, true)
						if has_explicit_type {
							v.out.write_rune(`)`)
						}
						v.out.write_string(if i != stmt.values.len - 1 { ',' } else { '' })
					}
				} else {
					v.out.write_string(type_to_default_value(stmt.@type))
				}
			}
		}
		IncDecStmt {
			v.out.write_string('$stmt.var$stmt.inc')
		}
		CallStmt {
			v.out.write_string('${stmt.namespaces}(')
			for i, arg in stmt.args {
				v.write_stmt(arg, true)
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
				v.out.write_string('{\n')
				v.write_body(branch.body)
				v.out.write_rune(`}`)
			}
		}
		ForStmt {
			v.out.write_string('for ')
			// check if stmt.init or stmt.post aren't null
			if stmt.init.names.len > 0 || stmt.post.type_name() != 'unknown transpiler.Statement' {
				// c-style for
				v.write_stmt(stmt.init, true)
				v.out.write_string(';$stmt.condition;')
				v.write_stmt(stmt.post, true)
			} else {
				// while
				v.out.write_string(stmt.condition)
			}
			// for bare loops no need to write anything
			v.out.write_string('{\n')
			v.write_body(stmt.body)
			v.out.write_rune(`}`)
		}
		ForInStmt {
			if stmt.idx.len > 0 || stmt.element.len > 0 {
				v.out.write_string('for $stmt.idx, $stmt.element in ')
			} else {
				v.out.write_string('for _ in ')
			}
			v.write_stmt(stmt.variable, true)
			v.out.write_string('{\n')
			v.write_body(stmt.body)
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
					v.write_stmt(el, true)
					v.out.write_rune(`,`)
				}

				mut i := stmt.values.len
				if is_fixed_size && i < stmt.len.int() {
					mut is_first := true
					for i != stmt.len.int() {
						if is_first {
							is_first = false
							v.out.write_string(type_to_default_value(stmt.@type))
						} else {
							v.out.write_string(', ${type_to_default_value(stmt.@type)}')
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
			v.out.write_string('$stmt.value[')
			v.write_stmt(stmt.low, true)
			v.out.write_string('..')
			v.write_stmt(stmt.high, true)
			v.out.write_rune(`]`)
		}
		ReturnStmt {
			v.out.write_string('return ')
			for i, el in stmt.values {
				v.write_stmt(el, true)
				// TODO: useless after https://github.com/vlang/v/issues/13592 gets fixed
				if i != stmt.values.len - 1 {
					v.out.write_rune(`,`)
				}
			}
		}
		DeferStmt {
			v.out.write_string('defer {')
			v.write_stmt(stmt.stmt, true)
			v.out.write_rune(`}`)
		}
		UnsafeStmt {
			v.out.write_string('unsafe {')
			v.write_body(stmt.body)
			v.out.write_rune(`}`)
		}
		MatchStmt {
			v.write_stmt(stmt.init, true)

			v.out.write_string('match ')
			v.write_stmt(stmt.value, true)
			v.out.write_rune(`{`)
			for case in stmt.cases {
				if case.values.len > 0 {
					for i, value in case.values {
						if i > 0 {
							v.out.write_rune(`,`)
						}
						v.write_stmt(value, true)
					}
				} else {
					v.out.write_string('else')
				}
				v.out.write_string('{\n')
				v.write_body(case.body)
				v.out.write_rune(`}`)
			}
			v.out.write_rune(`}`)
		}
		StructStmt {
			v.out.write_string('$stmt.name{')
			for i, field in stmt.fields {
				if i > 0 {
					v.out.write_rune(`,`)
				}
				v.write_stmt(field, true)
			}
			v.out.write_rune(`}`)
		}
		KeyValStmt {
			v.out.write_string('\n$stmt.key:')
			v.write_stmt(stmt.value, true)
		}
		MapStmt {
			if stmt.values.len > 0 {
				v.out.write_rune(`{`)
				for value in stmt.values {
					v.write_stmt(value, true)
				}
				v.out.write_rune(`}`)
			} else {
				v.out.write_string('map[$stmt.key_type]$stmt.value_type')
			}
		}
		PushStmt {
			v.write_stmt(stmt.stmt, true)
			v.out.write_string('<<')
			v.write_stmt(stmt.value, true)
		}
		ComplexValueStmt {
			v.out.write_string(stmt.op)
			v.write_stmt(stmt.value, true)
		}
		OptionalStmt {
			v.write_stmt(stmt.stmt, true)
			v.out.write_rune(`?`)
		}
		MultipleStmt {
			for el in stmt.stmts {
				v.write_stmt(el, true)
			}
		}
		NotYetImplStmt {
			v.out.write_string('NOT_YET_IMPLEMENTED')
		}
	}

	if is_value {
		v.out.write_rune(` `)
	} else {
		v.out.write_rune(`\n`)
	}
}
