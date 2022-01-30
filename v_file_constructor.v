import strings

fn v_file_constructor(v_ast VAST) string {
	mut out := strings.new_builder(200)

	// fc stands for file constructor, to prevent name collisions with the AST constructor stage's functions
	fc_module(v_ast, mut out)
	fc_imports(v_ast, mut out)
	fc_types(v_ast, mut out)
	fc_structs(v_ast, mut out)

	return out.str()
}

fn fc_module(v_ast VAST, mut out strings.Builder) {
	out.writeln('module ${v_ast.@module}')
	out.writeln('')
}

fn fc_imports(v_ast VAST, mut out strings.Builder) {
	for imp in v_ast.imports {
		out.writeln('import $imp')
	}
	out.writeln('')
}

fn fc_types(v_ast VAST, mut out strings.Builder) {
	for name, typ in v_ast.types {
		out.writeln('type $name = $typ')
	}
	out.writeln('')
}

fn fc_structs(v_ast VAST, mut out strings.Builder) {
	for strct in v_ast.structs {
		out.writeln('struct $strct.name {')
		for field, typ in strct.fields {
			out.writeln('\t$field $typ')
		}
		out.writeln('}')
		out.writeln('')
	}
}
