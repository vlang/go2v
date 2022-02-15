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
	v.out.write_rune(`\n`)
}

fn (mut v VAST) handle_imports() {
	if v.imports.len != 0 {
		for imp in v.imports {
			v.out.writeln('import $imp')
		}
		v.out.write_rune(`\n`)
	}
}

fn (mut v VAST) handle_types() {
	if v.types.len != 0 {
		for name, typ in v.types {
			v.out.writeln('type $name = $typ')
		}
		v.out.write_rune(`\n`)
	}
}

fn (mut v VAST) handle_structs() {
	for strct in v.structs {
		v.out.write_string('struct $strct.name {')
		if strct.fields.len != 0 {
			for field, typ in strct.fields {
				v.out.write_string('\n\t$field $typ')
			}
			v.out.write_string('\n}')
		} else {
			v.out.write_string('}')
		}
		v.out.writeln('\n')
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
				v.out.writeln('\t$key = $val')
			}
			v.out.writeln(')')
		}
		v.out.write_rune(`\n`)
	}
}

fn (mut v VAST) handle_enums() {
	for enm in v.enums {
		v.out.writeln('enum $enm.name {')
		for name, val in enm.fields {
			if val.len == 0 {
				v.out.writeln('\t$name')
			} else {
				v.out.writeln('\t$name = $val')
			}
		}
		v.out.writeln('}\n')
	}
}

fn (mut v VAST) handle_functions() {
	for func in v.functions {
		// comment
		if func.comment != '' {
			v.out.writeln(func.comment)
		}
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
		mut len := func.args.len
		for name, @type in func.args {
			len--
			if len == 0 {
				v.out.write_string('$name ${@type}')
			} else {
				v.out.write_string('$name ${@type}, ')
			}
		}
		v.out.write_string(')')
		// return value(s)
		if func.ret_vals.len == 1 {
			v.out.write_string(' ${func.ret_vals[0]}')
		} else if func.ret_vals.len != 0 {
			v.out.write_string(' (')
			len = func.ret_vals.len
			for i, val in func.ret_vals {
				if i != len - 1 {
					v.out.write_string('$val, ')
				} else {
					v.out.write_string('$val')
				}
			}
			v.out.write_string(')')
		}
		// body
		if func.body.len != 0 {
			v.out.write_string(' {\n')
		} else {
			v.out.write_string(' {')
		}
		v.handle_function_body(func.body)
		v.out.write_string('}\n\n')
	}
}

fn (mut v VAST) handle_function_body(body []Statement) {
	v.indent += '\t'

	for stmt in body {
		match stmt {
			VariableStmt {
				v.out.write_string(v.indent)
				stop := stmt.names.len - 1

				if stmt.mutable && stmt.declaration {
					v.out.write_string('mut ')
				}

				for i, name in stmt.names {
					comma := if i != stop { ',' } else { '' }
					v.out.write_string('$name$comma ')
				}
				middle := if stmt.declaration { ':=' } else { '=' }
				v.out.write_string(middle)
				for i, value in stmt.values {
					comma := if i != stop { ',' } else { '' }
					v.out.write_string(' $value$comma')
				}
				v.out.write_rune(`\n`)
			}
			CallStmt {
				v.out.write_string(v.indent)
				stop_ns := stmt.namespaces.len - 1

				for i, ns in stmt.namespaces {
					if i != stop_ns {
						v.out.write_string('${ns.name}.')
					} else {
						v.out.write_string('${ns.name}(')
						stop_arg := ns.args.len - 1
						for j, arg in ns.args {
							comma := if j != stop_arg { ', ' } else { '' }
							v.out.write_string('$arg$comma')
						}
						v.out.writeln(')')
					}
				}
			}
			IfStmt {
				for i, branch in stmt.branchs {
					if i != 0 {
						v.out.write_string('else ')
					} else {
						v.out.write_string(v.indent)
					}
					if branch.condition != ' ' {
						v.out.write_string('if $branch.condition ')
					}
					v.out.writeln('{')
					v.handle_function_body(branch.body)
					v.out.write_string(v.indent)
					if i != stmt.branchs.len - 1 {
						v.out.write_string('} ')
					} else {
						v.out.write_string('}\n')
					}
				}
			}
		}
	}

	v.indent = v.indent#[..-1]
}
