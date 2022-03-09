module transpiler

import strings

// root

struct VAST {
mut:
	// AST
	@module    string
	imports    []string
	consts     map[string]string
	structs    []StructLike
	unions     []StructLike
	interfaces []StructLike
	enums      []StructLike
	types      map[string]string
	functions  []Function
	// `v_file_constructor.v`
	out strings.Builder = strings.new_builder(400)
	// `v_style.v`
	fmt_import_count       int
	fmt_supported_fn_count int
	// maps
	current_implicit_map_type string
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
	| DeferStmt
	| ForInStmt
	| ForStmt
	| IfStmt
	| IncDecStmt
	| KeyValStmt
	| MapStmt
	| MatchStmt
	| NotImplYetStmt
	| PushStmt
	| ReturnStmt
	| SliceStmt
	| StructStmt
	| VariableStmt

struct NotImplYetStmt {}

struct VariableStmt {
mut:
	comment string
	names   []string
	middle  string
	values  []Statement
	mutable bool = true
	@type   string
}

struct ArrayStmt {
mut:
	@type  string
	values []Statement
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

struct DeferStmt {
mut:
	value Statement
}

struct MatchStmt {
mut:
	init  Statement
	value Statement
	cases []MatchCase
}

struct MatchCase {
mut:
	values []Statement
	body   []Statement
}

struct StructStmt {
mut:
	name   string
	fields []Statement
}

struct KeyValStmt {
	key   string
	value Statement
}

struct MapStmt {
mut:
	key_type   string
	value_type string
	values     []Statement
}

struct PushStmt {
mut:
	stmt  Statement
	value Statement
}
