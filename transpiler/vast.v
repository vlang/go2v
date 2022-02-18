module transpiler

import strings

// root

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
	out    strings.Builder = strings.new_builder(200)
	indent string
}

struct StructLike {
mut:
	name   string
	fields map[string]string
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

// body

type Statement = BranchStmt | CallStmt | ForStmt | IfStmt | IncDecStmt | VariableStmt

struct VariableStmt {
mut:
	comment string
	names   []string
	middle  string
	values  []string
	mutable bool = true
}

struct IncDecStmt {
mut:
	var string
	inc string
}

struct CallStmt {
mut:
	comment    string
	namespaces string
	args       []string
}

struct IfStmt {
mut:
	branchs []IfElse
}

struct IfElse {
mut:
	condition string
	body      []Statement
}

struct ForStmt {
mut:
	is_for_in bool
	body      []Statement
	// C-style & while loops specific
	init      VariableStmt
	condition string
	post      ForPost
	// for-in loop specific
	vars []VariableStmt
	var  VariableStmt
}

type ForPost = IncDecStmt | VariableStmt

struct BranchStmt {
	name string
}
