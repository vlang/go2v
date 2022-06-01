module transpiler

import strings

struct VAST {
mut:
	// AST
	@module    string
	imports    []string
	consts     []VariableStmt
	structs    []Struct
	unions     []StructLike
	interfaces []StructLike
	enums      []StructLike
	types      map[string]string
	functions  []FunctionStmt
	// `file_writer.v`
	out strings.Builder = strings.new_builder(400)
	// module_name utils
	used_imports map[string]bool = {}
	// string builders utils
	current_var_name    string
	string_builder_vars []string
	// maps utils
	current_implicit_map_type string
	// duplicate names utils
	declared_vars_old []string
	declared_vars_new []string
	all_declared_vars []string
	// TODO: check that it really works
	struct_fields       []string
	declared_global_old []string
	declared_global_new []string
	// struct utils
	vars_with_struct_value map[string]string
	// method utils
	current_method_var_name string
}

struct Struct {
	StructLike
mut:
	embedded_structs []string
}

struct StructLike {
mut:
	name   string
	fields map[string]Statement
}

// statements

type Statement = ArrayStmt
	| BasicValueStmt
	| BlockStmt
	| BranchStmt
	| CallStmt
	| ComplexValueStmt
	| DeferStmt
	| ForInStmt
	| ForStmt
	| FunctionStmt
	| GoStmt
	| IfStmt
	| IncDecStmt
	| KeyValStmt
	| LabelStmt
	| MapStmt
	| MatchStmt
	| MultipleStmt
	| NotYetImplStmt
	| OptionalStmt
	| PushStmt
	| ReturnStmt
	| SliceStmt
	| StructStmt
	| UnsafeStmt
	| VariableStmt

struct NotYetImplStmt {}

struct MultipleStmt {
mut:
	stmts []Statement
}

struct FunctionStmt {
mut:
	comment  string
	public   bool
	generic  bool
	method   []string
	name     string
	args     map[string]string
	ret_vals []string
	type_ctx bool
	body     []Statement
}

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
	low   Statement
	high  Statement
}

struct BasicValueStmt {
mut:
	value string
}

struct ComplexValueStmt {
	op    string
	value Statement
}

struct OptionalStmt {
	stmt Statement
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
	init_vars []VariableStmt
	branchs   []IfElse
}

struct IfElse {
mut:
	condition Statement
	body      []Statement
}

struct ForStmt {
mut:
	init      VariableStmt
	condition Statement
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
	name  string
	label string
}

struct ReturnStmt {
mut:
	values []Statement
}

struct DeferStmt {
mut:
	body []Statement
}

struct UnsafeStmt {
mut:
	body []Statement
}

struct MatchStmt {
mut:
	init  VariableStmt
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
mut:
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

struct LabelStmt {
mut:
	name string
	stmt Statement
}

struct GoStmt {
mut:
	stmt Statement
}

struct BlockStmt {
mut:
	body []Statement
}
