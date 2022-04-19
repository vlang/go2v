module transpiler

import strings

// root

const supported_modules = ['fmt', 'strings', 'bytes', 'strconv']

struct VAST {
mut:
	// AST
	@module    string
	imports    []string
	consts     []VariableStmt
	structs    []StructLike
	unions     []StructLike
	interfaces []StructLike
	enums      []StructLike
	types      map[string]string
	functions  []FunctionStmt
	// `v_file_constructor.v`
	out strings.Builder = strings.new_builder(400)
	// module_name utils
	// [initial_number_of_use, number_of_use_after_v_style]
	unused_import map[string]bool
	// string builders utils
	current_var_name    string
	string_builder_vars []string
	// maps utils
	current_implicit_map_type string
	// duplicate names utils
	declared_vars_old         []string
	declared_vars_new         []string
	declared_global_scope_old []string
	declared_global_scope_new []string
}

fn (mut v VAST) build_imports_count() {
	for module_name in transpiler.supported_modules {
		v.unused_import[module_name] = false
	}
}

struct StructLike {
mut:
	name   string
	fields map[string]Statement
}

// body

type Statement = ArrayStmt
	| BasicValueStmt
	| BranchStmt
	| CallStmt
	| ComplexValueStmt
	| DeferStmt
	| ForInStmt
	| ForStmt
	| FunctionStmt
	| IfStmt
	| IncDecStmt
	| KeyValStmt
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
	stmt Statement
}

struct UnsafeStmt {
mut:
	body []Statement
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
