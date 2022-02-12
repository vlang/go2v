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
	out           strings.Builder = strings.new_builder(200)
	declared_vars []string
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

type Statement = CallStmt | VariableStmt

struct VariableStmt {
mut:
	comment     string
	names       []string
	values      []string
	declaration bool
	mutable     bool = true
}

struct CallStmt {
mut:
	comment    string
	namespaces []Namespace
}

// in `a.b.c(...)` `a`, `b` and `c(...)` are namespaces
struct Namespace {
mut:
	name string
	args []string
}

fn ast_constructor(tree Tree) VAST {
	mut v_ast := VAST{}

	v_ast.get_module(tree)
	for _, el in tree.child['Decls'].tree.child {
		v_ast.get_all(el.tree, false)
	}

	v_ast.v_style()

	return v_ast
}

fn (mut v VAST) get_all(tree Tree, embedded bool) {
	// Go AST structure is different if embedded or not
	base := tree.child['Specs'].tree
	mut simplified_base := base.child['0'].tree
	mut type_field_name := 'Tok'

	if embedded {
		simplified_base = tree.child['Decl'].tree
		type_field_name = 'Kind'
	}

	match tree.child[type_field_name].val {
		// imports will never be embedded
		'import' {
			v.get_imports(tree)
		}
		'type' {
			if simplified_base.child['Type'].tree.name == '*ast.StructType' {
				if !embedded {
					for _, decl in base.child {
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
			// enums will never be embedded
			v.get_consts_and_enums(base)
		}
		else {
			// functions
			if tree.name == '*ast.FuncDecl' && !embedded {
				v.get_functions(tree)
			} else if simplified_base.name == '*ast.FuncDecl' {
				v.get_functions(simplified_base)
			}
		}
	}
}

fn (mut v VAST) get_module(tree Tree) {
	v.@module = v.get_name(tree, true, true)
}

fn (mut v VAST) get_imports(tree Tree) {
	for _, imp in tree.child['Specs'].tree.child {
		v.imports << imp.tree.child['Path'].tree.child['Value'].val#[3..-3].replace('/',
			'.')
	}
}

fn (mut v VAST) get_struct(tree Tree) StructLike {
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

fn (mut v VAST) get_types(tree Tree) {
	v.types[v.get_name(tree, true, false)] = v.get_type(tree)
}

fn (mut v VAST) get_consts_and_enums(tree Tree) {
	mut is_enum := false
	mut temp_enum := StructLike{}

	for _, @const in tree.child {
		name_base := @const.tree.child['Names'].tree.child['0'].tree

		mut val := v.get_value(@const.tree.child['Values'].tree.child['0'].tree)

		// Enums
		if val == 'iota' && !is_enum {
			// Begining of enum
			is_enum = true
			temp_enum.name = v.get_type(@const.tree)
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
		name: v.get_name(tree, true, true)
	}

	// Comments on top functions (docstrings)
	if 'Doc' in tree.child {
		func.comment = '//' +
			tree.child['Doc'].tree.child['List'].tree.child['0'].tree.child['Text'].val#[3..-5].replace('\\n', '\n// ').replace('\\t', '\t')
	}

	// Public/private
	temp_name := tree.child['Name'].tree.child['Name'].val#[1..-1]
	if `A` <= temp_name[0] && temp_name[0] <= `Z` {
		func.public = true
	}

	// Arguments
	for _, arg in tree.child['Type'].tree.child['Params'].tree.child['List'].tree.child {
		func.args[v.get_name(arg.tree.child['Names'].tree.child['0'].tree, false, true)] = v.get_type(arg.tree)
	}

	// Method
	if 'Recv' in tree.child {
		base := tree.child['Recv'].tree.child['List'].tree.child['0'].tree
		func.method = [
			v.get_name(base.child['Names'].tree.child['0'].tree, false, true),
			v.get_type(base),
		]
	}

	// Return value(s)
	for _, arg in tree.child['Type'].tree.child['Results'].tree.child['List'].tree.child {
		func.ret_vals << v.get_type(arg.tree)
	}

	// Body
	for _, stmt in tree.child['Body'].tree.child['List'].tree.child {
		match stmt.tree.name {
			// `var` syntax
			'*ast.DeclStmt' {
				base := stmt.tree.child['Decl'].tree.child['Specs'].tree.child['0'].tree

				mut names := []string{}
				mut values := []string{}

				for _, var in base.child['Names'].tree.child {
					names << v.get_name(var.tree, false, true)
				}
				for _, var in base.child['Values'].tree.child {
					values << v.get_value(var.tree)
				}

				v.declared_vars << names

				func.body << VariableStmt{
					names: names
					values: values
					declaration: true
				}
			}
			// `:=` & `=` syntax
			'*ast.AssignStmt' {
				mut names := []string{}
				mut values := []string{}

				for _, var in stmt.tree.child['Lhs'].tree.child {
					names << v.get_name(var.tree, false, true)
				}
				for _, var in stmt.tree.child['Rhs'].tree.child {
					if 'Type' !in var.tree.child {
						values << v.get_value(var.tree)
					} else {
						// structs
						values << v.get_value(var.tree.child['Type'].tree)
					}
				}

				v.declared_vars << names

				func.body << VariableStmt{
					names: names
					values: values
					declaration: stmt.tree.child['Tok'].val == ':='
				}
			}
			// function/method call
			'*ast.ExprStmt' {
				base := stmt.tree.child['X'].tree

				v.get_embedded(base.child['Fun'].tree)

				// namespaces, see struct Namespace for explaination
				mut namespaces := v.get_namespaces(base.child['Fun'].tree)

				// function/method arguments
				for _, arg in base.child['Args'].tree.child {
					namespaces[0].args << v.get_value(arg.tree)
				}

				func.body << CallStmt{
					namespaces: namespaces.reverse()
				}
			}
			else {}
		}
	}

	v.functions << func
}
