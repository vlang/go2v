// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
import json
import os

type Decls = FuncDecl | GenDecl

type Expr = InvalidExpr
	| ArrayType
	| FuncType
	| BasicLit
	| BinaryExpr
	| CallExpr
	| CompositeLit
	| Ellipsis
	| FuncLit
	| Ident
	| IndexExpr
	| KeyValueExpr
	| MapType
	| ParenExpr
	| SelectorExpr
	| SliceExpr
	| StarExpr
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

struct InvalidExpr {}

type Specs = ImportSpec | TypeSpec | ValueSpec

type Type = InvalidExpr
	| StructType
	| ArrayType
	| MapType
	| FuncType
	| InterfaceType
	| Ident
	| StarExpr
	| SelectorExpr

struct GoFile {
	package_name Ident   @[json: 'Name']
	decls        []Decls @[json: 'Decls']
}

struct Doc {
	list []struct {
		text string @[json: 'Text']
	} @[json: 'List']
}

struct FuncDecl {
	node_type string    @[json: '_type']
	doc       Doc       @[json: 'Doc']
	recv      FieldList @[json: 'Recv']
	name      Ident     @[json: 'Name']
	typ       FuncType  @[json: 'Type']
	body      BlockStmt @[json: 'Body']
}

struct GenDecl {
	node_type string  @[json: '_type']
	doc       Doc     @[json: 'Doc']
	tok       string  @[json: 'Tok']
	specs     []Specs @[json: 'Specs']
}

struct ImportSpec {
	node_type string   @[json: '_type']
	name      Ident    @[json: 'Name']
	path      BasicLit @[json: 'Path']
}

struct TypeSpec {
	node_type string    @[json: '_type']
	name      Ident     @[json: 'Name']
	params    FieldList @[json: 'TypeParams']
	typ       Type      @[json: 'Type']
}

struct ArrayType {
	node_type string @[json: '_type']
	len       Expr   @[json: 'Len']
	elt       Expr   @[json: 'Elt']
}

struct MapType {
	node_type string @[json: '_type']
	key       Expr   @[json: 'Key']
	val       Expr   @[json: 'Value']
}

struct Ellipsis {
	node_type string @[json: '_type']
	elt       Ident  @[json: 'Elt']
}

struct FuncType {
	node_type string    @[json: '_type']
	params    FieldList @[json: 'Params']
	results   FieldList @[json: 'Results']
}

struct ValueSpec {
	node_type string  @[json: '_type']
	names     []Ident @[json: 'Names']
	typ       Type    @[json: 'Type']
	values    []Expr  @[json: 'Values']
}

struct DeclStmt {
	node_type string @[json: '_type']
	decl      Decls  @[json: 'Decl']
}

struct BlockStmt {
	node_type string @[json: '_type']
	list      []Stmt @[json: 'List']
}

struct SwitchStmt {
	node_type string     @[json: '_type']
	init      AssignStmt @[json: 'Init']
	tag       Expr       @[json: 'Tag']
	body      BlockStmt  @[json: 'Body']
}

struct CaseClause {
	node_type string @[json: '_type']
	list      []Expr @[json: 'List']
	body      []Stmt @[json: 'Body']
}

struct IfStmt {
	node_type string     @[json: '_type']
	cond      Expr       @[json: 'Cond']
	init      AssignStmt @[json: 'Init']
	body      BlockStmt  @[json: 'Body']
	else_     Stmt       @[json: 'Else']
}

struct ForStmt {
	node_type string     @[json: '_type']
	init      AssignStmt @[json: 'Init']
	cond      Expr       @[json: 'Cond']
	post      Stmt       @[json: 'Post']
	body      BlockStmt  @[json: 'Body']
}

struct ExprStmt {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
}

struct AssignStmt {
	node_type string @[json: '_type']
	lhs       []Expr @[json: 'Lhs']
	rhs       []Expr @[json: 'Rhs']
	tok       string @[json: 'Tok']
}

struct StructType {
	node_type  string    @[json: '_type']
	fields     FieldList @[json: 'Fields']
	incomplete bool      @[json: 'Incomplete']
}

struct InterfaceType {
	node_type string    @[json: '_type']
	methods   FieldList @[json: 'Methods']
}

struct FieldList {
	list []Field @[json: 'List']
}

struct Field {
	node_type string  @[json: '_type']
	names     []Ident @[json: 'Names']
	typ       Type    @[json: 'Type']
	doc       Doc     @[json: 'Doc']
}

struct Ident {
	node_type string @[json: '_type']
	name      string @[json: 'Name']
}

struct BasicLit {
	node_type string @[json: '_type']
	kind      string @[json: 'Kind']
	value     string @[json: 'Value']
}

struct CallExpr {
	node_type string @[json: '_type']
	fun       Expr   @[json: 'Fun']
	args      []Expr @[json: 'Args']
}

struct SelectorExpr {
	node_type string @[json: '_type']
	sel       Ident  @[json: 'Sel']
	x         Expr   @[json: 'X']
}

struct CompositeLit {
	node_type string @[json: '_type']
	typ       Expr   @[json: 'Type']
	elts      []Expr @[json: 'Elts']
}

struct BinaryExpr {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
	op        string @[json: 'Op']
	y         Expr   @[json: 'Y']
}

struct UnaryExpr {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
	op        string @[json: 'Op']
}

struct KeyValueExpr {
	key       Expr   @[json: 'Key']
	value     Expr   @[json: 'Value']
	node_type string @[json: '_type']
}

struct IncDecStmt {
	node_type string @[json: '_type']
	tok       string @[json: 'Tok']
	x         Expr   @[json: 'X']
}

struct IndexExpr {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
	index     Expr   @[json: 'Index']
}

// `for ... := range` loop
struct RangeStmt {
	node_type string    @[json: '_type']
	key       Ident     @[json: 'Key']
	value     Ident     @[json: 'Value']
	tok       string    @[json: 'Tok']
	x         Expr      @[json: 'X']
	body      BlockStmt @[json: 'Body']
}

struct ParenExpr {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
}

struct SliceExpr {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
	low       Expr   @[json: 'Low']
	high      Expr   @[json: 'High']
}

struct StarExpr {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
}

struct DeferStmt {
	node_type string @[json: '_type']
	call      Expr   @[json: 'Call']
}

struct ReturnStmt {
	node_type string @[json: '_type']
	results   []Expr @[json: 'Results']
}

struct BranchStmt {
	node_type string @[json: '_type']
	tok       string @[json: 'Tok']
}

struct FuncLit {
	node_type string    @[json: '_type']
	typ       FuncType  @[json: 'Type']
	body      BlockStmt @[json: 'Body']
}

fn parse_go_ast(file_path string) !GoFile {
	data := os.read_file(file_path)!
	return json.decode(GoFile, data)!
}

fn (e Expr) node_type() string {
	match e {
		InvalidExpr { return 'InvalidExpr' }
		ArrayType { return e.node_type }
		BasicLit { return e.node_type }
		BinaryExpr { return e.node_type }
		CallExpr { return e.node_type }
		CompositeLit { return e.node_type }
		Ellipsis { return e.node_type }
		FuncLit { return e.node_type }
		Ident { return e.node_type }
		IndexExpr { return e.node_type }
		KeyValueExpr { return e.node_type }
		MapType { return e.node_type }
		ParenExpr { return e.node_type }
		SelectorExpr { return e.node_type }
		StarExpr { return e.node_type }
		SliceExpr { return e.node_type }
		UnaryExpr { return e.node_type }
		FuncType { return e.node_type }
	}
	return 'unknown node type'
}
