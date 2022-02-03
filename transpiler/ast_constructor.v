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
	enums      map[string]string
	types      map[string]string
	functions  []Function
	//
	out strings.Builder = strings.new_builder(200)
}

struct Function {
	name     string
	args     map[string]string
	ret_type []string
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
	base := if embedded { tree.child['Decl'].tree } else { tree.child['Specs'].tree.child['0'].tree }
	type_field_name := if embedded { 'Kind' } else { 'Tok' }

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
			v.get_consts(base)
		}
		else {}
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

fn (mut v VAST) get_consts(tree Tree) {
	base := tree.child['Values'].tree.child['0'].tree
	mut raw_val := if base.child['Value'].val.len != 0 {
		base.child['Value'].val // everything except bools
	} else {
		base.child['Name'].val // bools
	}

	raw_val = match raw_val[1] {
		`\\` { "'${raw_val#[3..-3]}'" } // strings
		`'` { '`${raw_val#[2..-2]}`' } // runes
		else { raw_val#[1..-1] } // numbers & bools
	}

	v.consts[tree.child['Names'].tree.child['0'].tree.child['Name'].val#[1..-1]] = raw_val
}
