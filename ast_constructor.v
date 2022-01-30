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

	package_name(tree, mut v_ast)

	for _, decl in tree.child['Decls'].tree.child.clone() {
		match decl.tree.child['Tok'].val {
			// package imports
			'import' {
				imports(decl.tree, mut v_ast)
			}
			'type' {
				if decl.tree.child['Specs'].tree.child['0'].tree.child['Type'].tree.name == '*ast.StructType' {
					structs(decl.tree, mut v_ast)
				} else {
					types(decl.tree, mut v_ast)
				}
			}
			else {}
		}
	}

	return v_ast
}

fn package_name(tree Tree, mut v_ast VAST) {
	v_ast.@module = tree.child['Name'].tree.child['Name'].val#[1..-1]
}

fn imports(decl Tree, mut v_ast VAST) {
	for _, imp in decl.child['Specs'].tree.child {
		v_ast.imports << imp.tree.child['Path'].tree.child['Value'].val#[3..-3]
	}
}

fn structs(decl Tree, mut v_ast VAST) {
	base := decl.child['Specs'].tree.child['0']
	mut @struct := StructLike{
		name: base.tree.child['Name'].tree.child['Name'].val#[1..-1]
	}

	for _, raw_field in base.tree.child['Type'].tree.child['Fields'].tree.child['List'].tree.child {
		mut val := ''
		if raw_field.tree.child['Type'].tree.name == '*ast.ArrayType' {
			val = '[]' +
				raw_field.tree.child['Type'].tree.child['Elt'].tree.child['Name'].val#[1..-1]
		} else {
			val = raw_field.tree.child['Type'].tree.child['Name'].val#[1..-1]
		}
		@struct.fields[raw_field.tree.child['Names'].tree.child['0'].tree.child['Name'].val#[1..-1]] = val
	}
	v_ast.structs << @struct
}

fn types(decl Tree, mut v_ast VAST) {
	v_ast.types[decl.child['Specs'].tree.child['0'].tree.child['Name'].tree.child['Name'].val#[1..-1]] = decl.child['Specs'].tree.child['0'].tree.child['Type'].tree.child['Name'].val#[1..-1]
}
