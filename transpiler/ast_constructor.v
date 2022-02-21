module transpiler

// TODO: handle comments

fn ast_constructor(tree Tree) VAST {
	mut v_ast := VAST{}

	v_ast.extract_module_name(tree)
	// go through each declaration node & extract the corresponding declaration
	for _, el in tree.child['Decls'].tree.child {
		v_ast.extract_declaration(el.tree, false)
	}

	return v_ast
}

fn (mut v VAST) extract_declaration(tree Tree, embedded bool) {
	base := tree.child['Specs'].tree
	mut simplified_base := base.child['0'].tree
	mut type_field_name := 'Tok'

	// Go AST structure is different if the declarating is embedded
	if embedded {
		simplified_base = tree.child['Decl'].tree
		type_field_name = 'Kind'
	}

	match tree.child[type_field_name].val {
		'import' {
			v.extract_imports(tree)
		}
		'type' {
			if simplified_base.child['Type'].tree.name == '*ast.StructType' {
				// structs
				if !embedded {
					for _, decl in base.child {
						v.structs << v.extract_struct(decl.tree)
					}
				} else {
					v.structs << v.extract_struct(simplified_base)
				}
				// sumtypes
			} else if simplified_base.name != '' {
				v.extract_sumtype(simplified_base)
			}
			// TODO: support interfaces
		}
		'const' {
			v.extract_const_or_enum(base)
		}
		else {
			// functions
			if tree.name == '*ast.FuncDecl' && !embedded {
				v.extract_function(tree)
			} else if simplified_base.name == '*ast.FuncDecl' {
				v.extract_function(simplified_base)
			}
		}
	}
}

fn (mut v VAST) extract_module_name(tree Tree) {
	v.@module = v.get_name(tree, true, true)
}

fn (mut v VAST) extract_imports(tree Tree) {
	for _, imp in tree.child['Specs'].tree.child {
		v.imports << imp.tree.child['Path'].tree.child['Value'].val#[3..-3].replace('/',
			'.')
	}
}

fn (mut v VAST) extract_struct(tree Tree) StructLike {
	mut @struct := StructLike{
		name: v.get_name(tree, true, false)
	}

	for _, field in tree.child['Type'].tree.child['Fields'].tree.child['List'].tree.child {
		// support `A, B int` syntax
		for _, name in field.tree.child['Names'].tree.child {
			@struct.fields[v.get_name(name.tree, false, true)] = v.get_type(field.tree)
		}
	}
	return @struct
}

fn (mut v VAST) extract_sumtype(tree Tree) {
	v.types[v.get_name(tree, true, false)] = v.get_type(tree)
}

fn (mut v VAST) extract_const_or_enum(tree Tree) {
	mut is_enum := false
	mut temp_enum := StructLike{}

	for _, @const in tree.child {
		name_base := @const.tree.child['Names'].tree.child['0'].tree

		mut val := v.get_value(@const.tree.child['Values'].tree.child['0'].tree)

		// enums
		if val == 'iota' && !is_enum {
			// begining of enum
			is_enum = true
			temp_enum.name = v.get_type(@const.tree)
			temp_enum.fields[name_base.child['Name'].val#[1..-1]] = ''
			// delete type used as enum name (Go enums implentation is so weird)
			v.types.delete(temp_enum.name)
		} else if is_enum {
			// inside of enum
			val = match val {
				'' { '' }
				'iota' { '' }
				else { val }
			}
			temp_enum.fields[name_base.child['Name'].val#[1..-1]] = val
		} else {
			// consts
			v.consts[name_base.child['Name'].val#[1..-1]] = val
		}
	}

	if is_enum {
		v.enums << temp_enum
	}
}

fn (mut v VAST) extract_function(tree Tree) {
	mut func := Function{
		name: v.get_name(tree, true, true)
	}

	// comments on top functions (docstrings)
	if 'Doc' in tree.child {
		func.comment = '//' +
			tree.child['Doc'].tree.child['List'].tree.child['0'].tree.child['Text'].val#[3..-5].replace('\\n', '\n// ').replace('\\t', '\t')
	}

	// public/private
	temp_name := tree.child['Name'].tree.child['Name'].val#[1..-1]
	if `A` <= temp_name[0] && temp_name[0] <= `Z` {
		func.public = true
	}

	// arguments
	for _, arg in tree.child['Type'].tree.child['Params'].tree.child['List'].tree.child {
		func.args[v.get_name(arg.tree.child['Names'].tree.child['0'].tree, false, true)] = v.get_type(arg.tree)
	}

	// method
	if 'Recv' in tree.child {
		base := tree.child['Recv'].tree.child['List'].tree.child['0'].tree
		func.method = [
			v.get_name(base.child['Names'].tree.child['0'].tree, false, true),
			v.get_type(base),
		]
	}

	// return value(s)
	for _, arg in tree.child['Type'].tree.child['Results'].tree.child['List'].tree.child {
		func.ret_vals << v.get_type(arg.tree)
	}

	// body
	func.body = v.get_body(tree.child['Body'].tree)

	v.functions << func
}
