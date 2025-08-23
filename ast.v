// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
import json
import os

type Decls = FuncDecl | GenDecl

type MapVal = Ident | InterfaceType | SelectorExpr

type Expr = InvalidExpr
	| ArrayType
	| BasicLit
	| BinaryExpr
	| CallExpr
	| CompositeLit
	| Ellipsis
	| FuncLit
	| FuncType
	| Ident
	| IndexExpr
	| KeyValueExpr
	| MapType
	| ParenExpr
	| SelectorExpr
	| SliceExpr
	| StarExpr
	| TypeAssertExpr
	| UnaryExpr

type Stmt = InvalidStmt
	| AssignStmt
	| BlockStmt
	| BranchStmt
	| CaseClause
	| DeclStmt
	| DeferStmt
	| ExprStmt
	| ForStmt
	| GoStmt
	| IfStmt
	| IncDecStmt
	| LabeledStmt
	| RangeStmt
	| ReturnStmt
	| SwitchStmt
	| TypeSwitchStmt

struct InvalidExpr {}

struct InvalidStmt {}

type Specs = ImportSpec | TypeSpec | ValueSpec

type Type = InvalidExpr
	| ArrayType
	| ChanType
	| FuncType
	| Ident
	| InterfaceType
	| MapType
	| SelectorExpr
	| StarExpr
	| StructType

struct ArrayType {
	node_type string @[json: '_type']
	len       Expr   @[json: 'Len']
	elt       Expr   @[json: 'Elt']
}

struct AssignStmt {
	node_type string @[json: '_type']
	lhs       []Expr @[json: 'Lhs']
	rhs       []Expr @[json: 'Rhs']
	tok       string @[json: 'Tok']
}

struct BasicLit {
	node_type string @[json: '_type']
	kind      string @[json: 'Kind']
	value     string @[json: 'Value']
}

struct BinaryExpr {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
	op        string @[json: 'Op']
	y         Expr   @[json: 'Y']
}

struct BlockStmt {
	node_type string @[json: '_type']
	list      []Stmt @[json: 'List']
}

struct BranchStmt {
	node_type string @[json: '_type']
	tok       string @[json: 'Tok']
	label     Ident  @[json: 'Label'] // only for `goto`
}

struct CallExpr {
	node_type string @[json: '_type']
	fun       Expr   @[json: 'Fun']
	args      []Expr @[json: 'Args']
}

struct CaseClause {
	node_type string @[json: '_type']
	list      []Expr @[json: 'List']
	body      []Stmt @[json: 'Body']
}

struct ChanType {
	node_type string @[json: '_type']
	dir       string @[json: 'Dir']
	value     Expr   @[json: 'Value']
}

struct CompositeLit {
	node_type string @[json: '_type']
	typ       Expr   @[json: 'Type']
	elts      []Expr @[json: 'Elts']
}

struct DeclStmt {
	node_type string @[json: '_type']
	decl      Decls  @[json: 'Decl']
}

struct DeferStmt {
	node_type string @[json: '_type']
	call      Expr   @[json: 'Call']
}

struct Doc {
	list []struct {
		text string @[json: 'Text']
	} @[json: 'List']
}

struct Ellipsis {
	node_type string @[json: '_type']
	elt       Ident  @[json: 'Elt']
}

struct ExprStmt {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
}

struct Field {
	node_type string  @[json: '_type']
	names     []Ident @[json: 'Names']
	typ       Type    @[json: 'Type']
	doc       Doc     @[json: 'Doc']
}

struct FieldList {
	list []Field @[json: 'List']
}

struct ForStmt {
	node_type string     @[json: '_type']
	init      AssignStmt @[json: 'Init']
	cond      Expr       @[json: 'Cond']
	post      Stmt       @[json: 'Post']
	body      BlockStmt  @[json: 'Body']
}

struct FuncDecl {
	node_type string    @[json: '_type']
	doc       Doc       @[json: 'Doc']
	recv      FieldList @[json: 'Recv']
	name      Ident     @[json: 'Name']
	typ       FuncType  @[json: 'Type']
	body      BlockStmt @[json: 'Body']
}

struct FuncLit {
	node_type string    @[json: '_type']
	typ       FuncType  @[json: 'Type']
	body      BlockStmt @[json: 'Body']
}

struct FuncType {
	node_type string    @[json: '_type']
	params    FieldList @[json: 'Params']
	results   FieldList @[json: 'Results']
}

struct GenDecl {
	node_type string  @[json: '_type']
	doc       Doc     @[json: 'Doc']
	tok       string  @[json: 'Tok']
	specs     []Specs @[json: 'Specs']
}

struct GoFile {
	package_name Ident   @[json: 'Name']
	decls        []Decls @[json: 'Decls']
}

struct GoStmt {
	node_type string @[json: '_type']
	call      Expr   @[json: 'Call']
}

struct Ident {
	node_type string @[json: '_type']
	name      string @[json: 'Name']
}

struct IfStmt {
	node_type string     @[json: '_type']
	cond      Expr       @[json: 'Cond']
	init      AssignStmt @[json: 'Init']
	body      BlockStmt  @[json: 'Body']
	else_     Stmt       @[json: 'Else']
}

struct ImportSpec {
	node_type string   @[json: '_type']
	name      Ident    @[json: 'Name']
	path      BasicLit @[json: 'Path']
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

struct InterfaceType {
	node_type string    @[json: '_type']
	methods   FieldList @[json: 'Methods']
}

struct KeyValueExpr {
	key       Expr   @[json: 'Key']
	value     Expr   @[json: 'Value']
	node_type string @[json: '_type']
}

struct LabeledStmt {
	node_type string @[json: '_type']
	label     Ident  @[json: 'Label']
	stmt      Stmt   @[json: 'Stmt']
}

struct MapType {
	node_type string @[json: '_type']
	key       Expr   @[json: 'Key']
	val       MapVal @[json: 'Value']
}

struct ParenExpr {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
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

struct ReturnStmt {
	node_type string @[json: '_type']
	results   []Expr @[json: 'Results']
}

struct SelectorExpr {
	node_type string @[json: '_type']
	sel       Ident  @[json: 'Sel']
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

struct StructType {
	node_type  string    @[json: '_type']
	fields     FieldList @[json: 'Fields']
	incomplete bool      @[json: 'Incomplete']
}

struct SwitchStmt {
	node_type string     @[json: '_type']
	init      AssignStmt @[json: 'Init']
	tag       Expr       @[json: 'Tag']
	body      BlockStmt  @[json: 'Body']
}

struct TypeAssertExpr {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
	typ       Type   @[json: 'Type']
}

struct TypeSpec {
	node_type string    @[json: '_type']
	name      Ident     @[json: 'Name']
	params    FieldList @[json: 'TypeParams']
	typ       Type      @[json: 'Type']
}

struct TypeSwitchStmt {
	node_type string     @[json: '_type']
	assign    AssignStmt @[json: 'Assign']
	// tag       Expr       @[json: 'Tag']
	body BlockStmt @[json: 'Body']
}

struct UnaryExpr {
	node_type string @[json: '_type']
	x         Expr   @[json: 'X']
	op        string @[json: 'Op']
}

struct ValueSpec {
	node_type string        @[json: '_type']
	names     []Ident       @[json: 'Names']
	typ       ValueSpecType @[json: 'Type']
	values    []Expr        @[json: 'Values']
}

struct ValueSpecType {
	node_type string @[json: '_type']
	name      string @[json: 'Name']
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
		FuncType { return e.node_type }
		Ident { return e.node_type }
		IndexExpr { return e.node_type }
		KeyValueExpr { return e.node_type }
		MapType { return e.node_type }
		ParenExpr { return e.node_type }
		SelectorExpr { return e.node_type }
		StarExpr { return e.node_type }
		SliceExpr { return e.node_type }
		TypeAssertExpr { return e.node_type }
		UnaryExpr { return e.node_type }
	}
	return 'unknown node type'
}
