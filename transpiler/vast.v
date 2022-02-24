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
	out strings.Builder = strings.new_builder(200)
	//
	fmt_import_count int
	println_fn_count int
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
	| ForInStmt
	| ForStmt
	| IfStmt
	| IncDecStmt
	| IndexStmt
	| NotImplYetStmt
	| ReturnStmt
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
	args       []Statement
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
	init      VariableStmt
	condition string
	post      Statement
	body      []Statement
}

struct ForInStmt {
mut:
	idx      string
	element  string
	variable Statement
	body     []Statement
}

struct BranchStmt {
	name string
}

struct ReturnStmt {
mut:
	values []Statement
}

struct IndexStmt {
mut:
	value string
}
