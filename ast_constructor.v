// TODO: handle comments

struct VAST {
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
	mut v_ast := VAST{
		@module: ((tree.child['Name'] or { tree } as Tree).child['Name'] or { '' } as string)#[1..-1]
	}

	return v_ast
}
