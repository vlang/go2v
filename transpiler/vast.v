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

type Statement = ArrayStmt
	| BasicValueStmt
	| BranchStmt
	| CallStmt
	| ForStmt
	| IfStmt
	| IncDecStmt
	| NotImplYetStmt
	| SliceStmt
	| VariableStmt

struct NotImplYetStmt {}

struct VariableStmt {
mut:
	comment string
	names   []string
	middle  string
	values  []Statement
	mutable bool = true
}

struct ArrayStmt {
mut:
	@type  string
	values []string
	len    string
}

struct SliceStmt {
mut:
	value string
	low   string
	high  string
}

struct BasicValueStmt {
	value string
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
	post      Statement
	// for-in loop specific
	vars []VariableStmt
	var  VariableStmt
}

struct BranchStmt {
	name string
}
