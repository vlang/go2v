module transpiler

fn v_file_constructor(v_ast VAST) string {
	mut v := v_ast
	v.handle_module()
	v.handle_imports()
	v.handle_types()
	v.handle_structs()
	v.handle_consts()

	return v.out.str()
}

fn (mut v VAST) handle_module() {
	v.out.writeln('module ${v.@module}')
	v.out.writeln('')
}

fn (mut v VAST) handle_imports() {
	if v.imports.len != 0 {
		for imp in v.imports {
			v.out.writeln('import $imp')
		}
		v.out.writeln('')
	}
}

fn (mut v VAST) handle_types() {
	if v.types.len != 0 {
		for name, typ in v.types {
			v.out.writeln('type $name = $typ')
		}
		v.out.writeln('')
	}
}

fn (mut v VAST) handle_structs() {
	for strct in v.structs {
		v.out.writeln('struct $strct.name {')
		for field, typ in strct.fields {
			v.out.writeln('\t$field $typ')
		}
		v.out.writeln('}')
		v.out.writeln('')
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
		v.out.writeln('')
	}
}
