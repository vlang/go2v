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
	// body     []Instruction
}

struct StructLike {
mut:
	name   string
	fields map[string]string
}

// TODO: will change as we need to set this list according to Go AST
// like we may group different similar in syntax instructions
/*
type Instruction = Assignment
	| Break
	| Continue
	| Else
	| Expression
	| For
	| FunctionCall
	| If
	| Return
	| Match
	| Comment
*/

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
	consts_base := tree.child['Specs'].tree
	mut base := consts_base.child['0'].tree
	mut type_field_name := 'Tok'

	if embedded {
		base = tree.child['Decl'].tree
		type_field_name = 'Kind'
	}

	match tree.child[type_field_name].val {
		// Will never be embedded
		'import' {
			v.get_imports(tree)
		}
		'type' {
			if base.child['Type'].tree.name == '*ast.StructType' {
				v.get_structs(base)
			} else if base.name != '' {
				v.get_types(base)
			}
		}
		'const' {
			// Enums will never be embedded
			v.get_consts_and_enums(consts_base)
		}
		else {
			if tree.name == '*ast.FuncDecl' {
				v.get_functions(tree)
			}
		}
	}
}

fn (mut v VAST) get_module(tree Tree) {
	v.@module = tree.child['Name'].tree.child['Name'].val#[1..-1]
}

fn (mut v VAST) get_imports(tree Tree) {
	for _, imp in tree.child['Specs'].tree.child {
		v.imports << imp.tree.child['Path'].tree.child['Value'].val#[3..-3]
	}
}

fn (mut v VAST) get_structs(tree Tree) {
	mut @struct := StructLike{
		name: tree.child['Name'].tree.child['Name'].val#[1..-1]
	}

	for _, raw_field in tree.child['Type'].tree.child['Fields'].tree.child['List'].tree.child {
		mut val := ''
		mut temp := raw_field.tree.child['Type']

		if raw_field.tree.child['Type'].tree.name == '*ast.ArrayType' {
			val = '[]'
			temp = raw_field.tree.child['Type'].tree.child['Elt']
		}

		@struct.fields[raw_field.tree.child['Names'].tree.child['0'].tree.child['Name'].val#[1..-1]] =
			val + temp.tree.child['Name'].val#[1..-1]

		// check if item embedded
		if 'Obj' in temp.tree.child {
			v.get_decl(temp.tree.child['Obj'].tree, true)
		}
	}

	v.structs << @struct
}

fn (mut v VAST) get_types(tree Tree) {
	mut val := ''
	mut temp := tree.child['Type']

	if tree.child['Type'].tree.name == '*ast.ArrayType' {
		val = '[]'
		temp = tree.child['Type'].tree.child['Elt']
	}

	v.types[tree.child['Name'].tree.child['Name'].val#[1..-1]] = val +
		temp.tree.child['Name'].val#[1..-1]

	// check if item embedded
	if 'Obj' in temp.tree.child {
		v.get_decl(temp.tree.child['Obj'].tree, true)
	}
}

fn (mut v VAST) get_consts_and_enums(tree Tree) {
	mut is_enum := false
	mut temp_enum := StructLike{}

	for _, @const in tree.child.clone() {
		val_base := @const.tree.child['Values'].tree.child['0'].tree
		name_base := @const.tree.child['Names'].tree.child['0'].tree

		raw_val := if val_base.child['Value'].val.len != 0 {
			val_base.child['Value'].val // everything except bools
		} else {
			val_base.child['Name'].val // bools & iotas (enums)
		}
		// Format the value
		mut val := raw_val
		if val.len != 0 {
			val = match raw_val[1] {
				`\\` { "'${raw_val#[3..-3]}'" } // strings
				`'` { '`${raw_val#[2..-2]}`' } // runes
				else { raw_val#[1..-1] } // numbers, bools, iotas (enums)
			}
		}

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
		name: tree.child['Name'].tree.child['Name'].val#[1..-1]
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
		// Get the type
		// TODO: create a reusuable function for this
		mut @type := ''
		mut temp := arg.tree.child['Type']
		if temp.tree.name == '*ast.ArrayType' {
			@type = '[]'
			temp = temp.tree.child['Elt']
		}
		@type += temp.tree.child['Name'].val#[1..-1]

		func.args[arg.tree.child['Names'].tree.child['0'].tree.child['Name'].val#[1..-1]] = @type

		// check if item embedded
		if 'Obj' in temp.tree.child {
			v.get_decl(temp.tree.child['Obj'].tree, true)
		}
	}

	// Method
	if 'Recv' in tree.child.clone() {
		base := tree.child['Recv'].tree.child['List'].tree.child['0'].tree
		func.method = [
			base.child['Names'].tree.child['0'].tree.child['Name'].val#[1..-1],
			base.child['Type'].tree.child['Name'].val#[1..-1],
		]

		// check if item embedded
		if base.child['Type'].tree.child['Obj'].val == '' {
			v.get_decl(base.child['Type'].tree.child['Obj'].tree, true)
		}
	}

	// Return value(s)
	for _, arg in tree.child['Type'].tree.child['Results'].tree.child['List'].tree.child.clone() {
		mut @type := ''
		mut temp := arg.tree.child['Type']
		if temp.tree.name == '*ast.ArrayType' {
			@type = '[]'
			temp = temp.tree.child['Elt']
		}
		func.ret_vals << @type + temp.tree.child['Name'].val#[1..-1]

		// check if item embedded
		if 'Obj' in temp.tree.child {
			v.get_decl(temp.tree.child['Obj'].tree, true)
		}
	}

	v.functions << func
}
