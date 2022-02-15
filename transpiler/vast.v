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
	out           strings.Builder = strings.new_builder(200)
	declared_vars []string
	indent        string
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

type Statement = CallStmt | IfStmt | VariableStmt

struct VariableStmt {
mut:
	comment     string
	names       []string
	values      []string
	declaration bool
	mutable     bool = true
}

struct CallStmt {
mut:
	comment    string
	namespaces []Namespace
}

// in `a.b.c(...)` `a`, `b` and `c(...)` are namespaces
struct Namespace {
mut:
	name string
	args []string
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
