module transpiler

import strings

struct VAST {
mut:
	// AST
	@module    string
	imports    map[string]string // map[name]alias
	consts     []VariableStmt
	structs    []Struct
	unions     []NameFields
	interfaces []NameFields
	enums      []NameFields
	types      map[string]string
	functions  []FunctionStmt
	// `file_writer.v`
	out strings.Builder = strings.new_builder(400)
	// `go2v_fns.v`
	// here a map is used a Set (array without duplicates), the value is useless
	enabled_go2v_fns map[string]bool
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
	// error utils
	vars_with_error_value []string
	// method utils
	current_method_var_name string
}

struct Struct {
	NameFields
mut:
	embedded_structs []string
}

struct NameFields {
mut:
	name   string
	fields map[string]Stmt
}

// statements

type Stmt = ArrayStmt
	| BlockStmt
	| BranchStmt
	| CallStmt
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
	| ValStmt
	| VariableStmt

struct NotYetImplStmt {}

struct MultipleStmt {
mut:
	stmts []Stmt
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
	body     []Stmt
}

struct VariableStmt {
mut:
	comment string
	names   []string
	middle  string
	values  []Stmt
	mutable bool = true
	@type   string
}

struct ArrayStmt {
mut:
	@type  string
	values []Stmt
	len    string
}

struct SliceStmt {
mut:
	value string
	low   Stmt
	high  Stmt
}

struct ValStmt {
mut:
	value string
}

struct OptionalStmt {
	stmt Stmt
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
	args       []Stmt
}

struct IfStmt {
mut:
	init_vars []VariableStmt
	branchs   []IfElse
}

struct IfElse {
mut:
	condition Stmt = ValStmt{}
	body      []Stmt
}

struct ForStmt {
mut:
	init      VariableStmt
	condition Stmt
	post      Stmt
	body      []Stmt
}

struct ForInStmt {
mut:
	idx      string
	element  string
	variable Stmt
	body     []Stmt
}

struct BranchStmt {
	name  string
	label string
}

struct ReturnStmt {
mut:
	values []Stmt
}

struct DeferStmt {
mut:
	body []Stmt
}

struct UnsafeStmt {
mut:
	body []Stmt
}

struct MatchStmt {
mut:
	init  VariableStmt
	value Stmt
	cases []MatchCase
}

struct MatchCase {
mut:
	values []Stmt
	body   []Stmt
}

struct StructStmt {
mut:
	name   string
	fields []Stmt
}

struct KeyValStmt {
mut:
	key   string
	value Stmt
}

struct MapStmt {
mut:
	key_type   string
	value_type string
	values     []Stmt
}

struct PushStmt {
mut:
	stmt  Stmt
	value Stmt
}

struct LabelStmt {
mut:
	name string
	stmt Stmt
}

struct GoStmt {
mut:
	stmt Stmt
}

struct BlockStmt {
mut:
	body []Stmt
}
