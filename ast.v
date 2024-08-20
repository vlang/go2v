// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
import json
import os

type Expr = ArrayType
	| BasicLit
	| BinaryExpr
	| CallExpr
	| CompositeLit
	| Ellipsis
	| FuncLit
	| Ident
	| IndexExpr
	| KeyValueExpr
	| ParenExpr
	| SelectorExpr
	| StarExpr
	| TypeOrIdent
	| UnaryExpr

type Stmt = AssignStmt
	| BlockStmt
	| BranchStmt
	| CaseClause
	| DeclStmt
	| DeferStmt
	| ExprStmt
	| ForStmt
	| IfStmt
	| IncDecStmt
	| RangeStmt
	| ReturnStmt
	| SwitchStmt

type Type2 = ArrayType | Ident | StarExpr

struct GoFile {
	name  Ident  @[json: 'Name']
	decls []Decl @[json: 'Decls']
}

struct Decl {
	node_type_str string    @[json: '_type']
	specs         []Spec    @[json: 'Specs']
	decls         []Decl    @[json: 'Decls']
	name          Ident     @[json: 'Name']
	typ           FuncType  @[json: 'Type']
	recv          FieldList @[json: 'Recv']
	body          BlockStmt @[json: 'Body']
	tok           string    @[json: 'Tok']
}

struct Spec {
	node_type_str string   @[json: '_type']
	name          Ident    @[json: 'Name']
	names         []Ident  @[json: 'Names']
	values        []Expr   @[json: 'Values']
	typ           Type     @[json: 'Type']
	args          []Expr   @[json: 'Args']
	path          BasicLit @[json: 'Path']
}

struct ArrayType {
	node_type_str string @[json: '_type']
	// elt           Ident  @[json: 'Elt']
	elt Expr @[json: 'Elt']
}

struct Ellipsis {
	node_type_str string @[json: '_type']
	elt           Ident  @[json: 'Elt']
}

struct FuncType {
	params  FieldList @[json: 'Params']
	results FieldList @[json: 'Results']
}

struct ValueSpec {
	node_type_str string @[json: '_type']

	names  []Ident     @[json: 'Names']
	typ    TypeOrIdent @[json: 'Type']
	values []Expr      @[json: 'Values']
}

struct DeclStmt {
	node_type_str string        @[json: '_type']
	decl          struct {
		tok   string      @[json: 'Tok']
		specs []ValueSpec @[json: 'Specs']
	} @[json: 'Decl']
}

struct BlockStmt {
	node_type_str string @[json: '_type']
	list          []Stmt @[json: 'List']
}

struct SwitchStmt {
	node_type_str string     @[json: '_type']
	init          AssignStmt @[json: 'Init']
	tag           Expr       @[json: 'Tag']
	body          BlockStmt  @[json: 'Body']
}

struct CaseClause {
	node_type_str string @[json: '_type']
	list          []Expr @[json: 'List']
	body          []Stmt @[json: 'Body']
}

struct IfStmt {
	node_type_str string     @[json: '_type']
	cond          Expr       @[json: 'Cond']
	init          AssignStmt @[json: 'Init']
	body          BlockStmt  @[json: 'Body']
	else_         Stmt       @[json: 'Else']
}

struct ForStmt {
	node_type_str string     @[json: '_type']
	init          AssignStmt @[json: 'Init']
	cond          Expr       @[json: 'Cond']
	post          Stmt       @[json: 'Post']

	body BlockStmt @[json: 'Body']
}

struct ExprStmt {
	node_type_str string @[json: '_type']
	x             Expr   @[json: 'X']
}

struct AssignStmt {
	node_type_str string @[json: '_type']
	lhs           []Expr @[json: 'Lhs']

	rhs []Expr @[json: 'Rhs']
	tok string @[json: 'Tok']
}

struct Type {
	node_type_str string    @[json: '_type']
	fields        FieldList @[json: 'Fields']
}

struct FieldList {
	list []Field @[json: 'List']
}

struct Field {
	node_type_str string  @[json: '_type']
	names         []Ident @[json: 'Names']
	// typ           TypeOrIdent @[json: 'Type']
	typ Type2 @[json: 'Type']
}

struct Ident {
	node_type_str string @[json: '_type']
	name          string @[json: 'Name']
}

struct TypeOrIdent {
	node_type_str string @[json: '_type']
	name          string @[json: 'Name']
	len           Expr   @[json: 'Len']
	elt           Ident  @[json: 'Elt']
}

struct BasicLit {
	node_type_str string @[json: '_type']
	kind          string @[json: 'Kind']
	value         string @[json: 'Value']
}

struct CallExpr {
	node_type_str string @[json: '_type']
	fun           Expr   @[json: 'Fun']
	args          []Expr @[json: 'Args']
}

struct SelectorExpr {
	node_type_str string @[json: '_type']
	sel           Ident  @[json: 'Sel']
	x             Expr   @[json: 'X']
}

// Foo{bar:baz}
// []bool{}
struct CompositeLit {
	node_type_str string      @[json: '_type']
	typ           TypeOrIdent @[json: 'Type']
	elts          []Expr      @[json: 'Elts']
}

/*
struct Elt {
	key struct {
		name string @[json: 'Name']
	} @[json: 'Key']

	value Expr @[json: 'Value']
}
*/

struct BinaryExpr {
	node_type_str string @[json: '_type']
	x             Expr   @[json: 'X']
	op            string @[json: 'Op']
	y             Expr   @[json: 'Y']
}

struct UnaryExpr {
	node_type_str string @[json: '_type']
	x             Expr   @[json: 'X']
	op            string @[json: 'Op']
}

struct KeyValueExpr {
	// key           Ident  @[json: 'Key']
	key           Expr   @[json: 'Key']
	value         Expr   @[json: 'Value']
	node_type_str string @[json: '_type']
}

struct IncDecStmt {
	node_type_str string @[json: '_type']
	tok           string @[json: 'Tok']
	x             Expr   @[json: 'X']
}

struct IndexExpr {
	x     Expr @[json: 'X']
	index Expr @[json: 'Index']

	node_type_str string @[json: '_type']
}

// `for ... := range` loop
struct RangeStmt {
	node_type_str string    @[json: '_type']
	key           Ident     @[json: 'Key']
	value         Ident     @[json: 'Value']
	tok           string    @[json: 'Tok']
	x             Expr      @[json: 'X']
	body          BlockStmt @[json: 'Body']
}

struct ParenExpr {
	node_type_str string @[json: '_type']
	x             Expr   @[json: 'X']
}

struct StarExpr {
	node_type_str string @[json: '_type']
	x             Expr   @[json: 'X']
}

struct DeferStmt {
	node_type_str string @[json: '_type']
	call          Expr   @[json: 'Call']
}

struct ReturnStmt {
	node_type_str string @[json: '_type']
	results       []Expr @[json: 'Results']
}

struct BranchStmt {
	node_type_str string @[json: '_type']
	tok           string @[json: 'Tok']
}

struct FuncLit {
	node_type_str string    @[json: '_type']
	typ           FuncType  @[json: 'Type']
	body          BlockStmt @[json: 'Body']
}

fn parse_go_ast(file_path string) !GoFile {
	data := os.read_file(file_path)!
	return json.decode(GoFile, data)!
}

fn (e Expr) node_type() string {
	match e {
		ArrayType { return e.node_type_str }
		BasicLit { return e.node_type_str }
		BinaryExpr { return e.node_type_str }
		CallExpr { return e.node_type_str }
		CompositeLit { return e.node_type_str }
		Ellipsis { return e.node_type_str }
		FuncLit { return e.node_type_str }
		Ident { return e.node_type_str }
		IndexExpr { return e.node_type_str }
		KeyValueExpr { return e.node_type_str }
		ParenExpr { return e.node_type_str }
		SelectorExpr { return e.node_type_str }
		StarExpr { return e.node_type_str }
		TypeOrIdent { return e.node_type_str }
		UnaryExpr { return e.node_type_str }
	}
	return 'unknown node type'
}
