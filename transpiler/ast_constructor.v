module transpiler

import strings

// TODO: handle comments

struct VAST {
mut:
	@module    string
	imports    []string
	consts     map[string]string
	structs    []StructLike
	unions     []StructLike
	interfaces []StructLike
	enums      []StructLike
	types      map[string]string
	functions  []Function
	//
	out strings.Builder = strings.new_builder(200)
}

struct Function {
mut:
	comment  string
	public   bool
	method   []string
	name     string
	args     map[string]string
	ret_vals []string
	body     []Statement
}

struct StructLike {
mut:
	name   string
	fields map[string]string
}

type Statement = Temp | VariableStmt

struct VariableStmt {
mut:
	comment     string
	names       []string
	values      []string
	declaration bool
}

struct Temp {}

fn ast_constructor(tree Tree) VAST {
	mut v_ast := VAST{}

	v_ast.get_module(tree)
	for _, el in tree.child['Decls'].tree.child.clone() {
		v_ast.get_decl(el.tree, false)
	}

	return v_ast
}

fn (mut v VAST) get_decl(tree Tree, embedded bool) {
	// Go AST structure is different if embedded or not
	base := tree.child['Specs'].tree
	mut simplified_base := base.child['0'].tree
	mut type_field_name := 'Tok'

	if embedded {
		simplified_base = tree.child['Decl'].tree
		type_field_name = 'Kind'
	}

	match tree.child[type_field_name].val {
		// Will never be embedded
		'import' {
			v.get_imports(tree)
		}
		'type' {
			if simplified_base.child['Type'].tree.name == '*ast.StructType' {
				if !embedded {
					for _, decl in base.child.clone() {
						v.structs << v.get_struct(decl.tree)
					}
				} else {
					v.structs << v.get_struct(simplified_base)
				}
			} else if simplified_base.name != '' {
				v.get_types(simplified_base)
			}
		}
		'const' {
			// Enums will never be embedded
			v.get_consts_and_enums(base)
		}
		else {
			if tree.name == '*ast.FuncDecl' {
				v.get_functions(tree)
			}
		}
	}
}

fn (mut v VAST) get_module(tree Tree) {
	v.@module = get_name(tree)
}

fn (mut v VAST) get_imports(tree Tree) {
	for _, imp in tree.child['Specs'].tree.child {
		v.imports << imp.tree.child['Path'].tree.child['Value'].val#[3..-3].replace('/',
			'.')
	}
}

fn (mut v VAST) get_struct(tree Tree) StructLike {
	mut @struct := StructLike{
		name: get_name(tree)
	}

	for _, field in tree.child['Type'].tree.child['Fields'].tree.child['List'].tree.child {
		// support `A, B int` syntax
		for _, name in field.tree.child['Names'].tree.child.clone() {
			@struct.fields[name.tree.child['Name'].val#[1..-1]] = v.get_type(field.tree)
		}
	}
	return @struct
}

fn (mut v VAST) get_types(tree Tree) {
	v.types[get_name(tree)] = v.get_type(tree)
}

fn (mut v VAST) get_consts_and_enums(tree Tree) {
	mut is_enum := false
	mut temp_enum := StructLike{}

	for _, @const in tree.child.clone() {
		name_base := @const.tree.child['Names'].tree.child['0'].tree

		mut val := get_value(@const.tree.child['Values'].tree.child['0'].tree)

		// Enums
		if val == 'iota' && !is_enum {
			// Begining of enum
			is_enum = true
			temp_enum.name = @const.tree.child['Type'].tree.child['Name'].val#[1..-1]
			temp_enum.fields[name_base.child['Name'].val#[1..-1]] = ''
			// Delete type used as enum name (Go enums implentation is so weird)
			v.types.delete(temp_enum.name)
		} else if is_enum {
			// Inside of enum
			val = match val {
				'' { '' }
				'iota' { '' }
				else { val }
			}
			temp_enum.fields[name_base.child['Name'].val#[1..-1]] = val
		} else {
			// Consts
			v.consts[name_base.child['Name'].val#[1..-1]] = val
		}
	}

	if is_enum {
		v.enums << temp_enum
	}
}

fn (mut v VAST) get_functions(tree Tree) {
	mut func := Function{
		name: get_name(tree)
	}

	// Comments on top functions (docstrings)
	if 'Doc' in tree.child.clone() {
		func.comment = '//' +
			tree.child['Doc'].tree.child['List'].tree.child['0'].tree.child['Text'].val#[3..-5].replace('\\n', '\n// ').replace('\\t', '\t')
	}

	// Public/private
	if `A` <= func.name[0] && func.name[0] <= `Z` {
		func.public = true
	}

	// Arguments
	for _, arg in tree.child['Type'].tree.child['Params'].tree.child['List'].tree.child.clone() {
		func.args[arg.tree.child['Names'].tree.child['0'].tree.child['Name'].val#[1..-1]] = v.get_type(arg.tree)
	}

	// Method
	if 'Recv' in tree.child.clone() {
		base := tree.child['Recv'].tree.child['List'].tree.child['0'].tree
		func.method = [
			base.child['Names'].tree.child['0'].tree.child['Name'].val#[1..-1],
			v.get_type(base),
		]
	}

	// Return value(s)
	for _, arg in tree.child['Type'].tree.child['Results'].tree.child['List'].tree.child.clone() {
		func.ret_vals << v.get_type(arg.tree)
	}

	// Body
	for _, stmt in tree.child['Body'].tree.child['List'].tree.child.clone() {
		match stmt.tree.name {
			'*ast.DeclStmt' {
				base := stmt.tree.child['Decl'].tree.child['Specs'].tree.child['0'].tree

				func.body << VariableStmt{
					names: [base.child['Names'].tree.child['0'].tree.child['Name'].val#[1..-1]]
					values: [base.child['Values'].tree.child['0'].tree.child['Value'].val#[1..-1]]
					declaration: true
				}
			}
			'*ast.AssignStmt' {
				mut names := []string{}
				mut values := []string{}

				for _, var in stmt.tree.child['Lhs'].tree.child.clone() {
					names << var.tree.child['Name'].val#[1..-1]
				}
				for _, var in stmt.tree.child['Rhs'].tree.child.clone() {
					values << get_value(var.tree)
				}

				func.body << VariableStmt{
					names: names
					values: values
					declaration: stmt.tree.child['Tok'].val == ':='
				}
			}
			else {}
		}
	}

	v.functions << func
}
