// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
import json2
import os

type Decls = FuncDecl | GenDecl

type MapVal = ArrayType
	| FuncType
	| Ident
	| InterfaceType
	| MapType
	| SelectorExpr
	| StarExpr
	| StructType

type Expr = InvalidExpr
	| ArrayType
	| BasicLit
	| BinaryExpr
	| CallExpr
	| ChanType
	| CompositeLit
	| Ellipsis
	| FuncLit
	| FuncType
	| Ident
	| IndexExpr
	| InterfaceType
	| KeyValueExpr
	| MapType
	| ParenExpr
	| SelectorExpr
	| SliceExpr
	| StarExpr
	| StructType
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
	| SendStmt
	| SwitchStmt
	| TypeSwitchStmt

struct InvalidExpr {}

struct InvalidStmt {}

type Specs = ImportSpec | TypeSpec | ValueSpec

type Type = InvalidExpr
	| ArrayType
	| ChanType
	| Ellipsis
	| FuncType
	| Ident
	| InterfaceType
	| MapType
	| SelectorExpr
	| StarExpr
	| StructType

struct ArrayType {
	node_type string                       @[json: '_type']
	len       &Expr = &Expr(InvalidExpr{}) @[json: 'Len']
	elt       &Expr = &Expr(InvalidExpr{}) @[json: 'Elt']
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
	node_type string                       @[json: '_type']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
	op        string                       @[json: 'Op']
	y         &Expr = &Expr(InvalidExpr{}) @[json: 'Y']
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
	node_type string                       @[json: '_type']
	fun       &Expr = &Expr(InvalidExpr{}) @[json: 'Fun']
	args      []Expr                       @[json: 'Args']
}

struct CaseClause {
	node_type string @[json: '_type']
	list      []Expr @[json: 'List']
	body      []Stmt @[json: 'Body']
}

struct ChanType {
	node_type string                       @[json: '_type']
	dir       string                       @[json: 'Dir']
	value     &Expr = &Expr(InvalidExpr{}) @[json: 'Value']
}

struct CompositeLit {
	node_type string                       @[json: '_type']
	typ       &Expr = &Expr(InvalidExpr{}) @[json: 'Type']
	elts      []Expr                       @[json: 'Elts']
}

struct DeclStmt {
	node_type string @[json: '_type']
	decl      Decls  @[json: 'Decl']
}

struct DeferStmt {
	node_type string                       @[json: '_type']
	call      &Expr = &Expr(InvalidExpr{}) @[json: 'Call']
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
	node_type string                       @[json: '_type']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
}

struct Field {
	node_type string                       @[json: '_type']
	names     []Ident                      @[json: 'Names']
	typ       &Type = &Type(InvalidExpr{}) @[json: 'Type']
	doc       Doc @[json: 'Doc']
}

struct FieldList {
	list []Field @[json: 'List']
}

struct ForStmt {
	node_type string                       @[json: '_type']
	init      AssignStmt                   @[json: 'Init']
	cond      &Expr = &Expr(InvalidExpr{}) @[json: 'Cond']
	post      &Stmt = &Stmt(InvalidStmt{}) @[json: 'Post']
	body      BlockStmt                    @[json: 'Body']
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
	node_type string                       @[json: '_type']
	call      &Expr = &Expr(InvalidExpr{}) @[json: 'Call']
}

struct Ident {
	node_type string @[json: '_type']
	name      string @[json: 'Name']
}

struct IfStmt {
	node_type string                       @[json: '_type']
	cond      &Expr = &Expr(InvalidExpr{}) @[json: 'Cond']
	init      AssignStmt                   @[json: 'Init']
	body      BlockStmt                    @[json: 'Body']
	else_     &Stmt = &Stmt(InvalidStmt{}) @[json: 'Else']
}

struct ImportSpec {
	node_type string   @[json: '_type']
	name      Ident    @[json: 'Name']
	path      BasicLit @[json: 'Path']
}

struct IncDecStmt {
	node_type string                       @[json: '_type']
	tok       string                       @[json: 'Tok']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
}

struct IndexExpr {
	node_type string                       @[json: '_type']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
	index     &Expr = &Expr(InvalidExpr{}) @[json: 'Index']
}

struct InterfaceType {
	node_type string    @[json: '_type']
	methods   FieldList @[json: 'Methods']
}

struct KeyValueExpr {
	key       &Expr = &Expr(InvalidExpr{}) @[json: 'Key']
	value     &Expr = &Expr(InvalidExpr{}) @[json: 'Value']
	node_type string                       @[json: '_type']
}

struct LabeledStmt {
	node_type string                       @[json: '_type']
	label     Ident                        @[json: 'Label']
	stmt      &Stmt = &Stmt(InvalidStmt{}) @[json: 'Stmt']
}

struct MapType {
	node_type string                         @[json: '_type']
	key       &Expr   = &Expr(InvalidExpr{}) @[json: 'Key']
	val       &MapVal = &MapVal(Ident{})     @[json: 'Value']
}

struct ParenExpr {
	node_type string                       @[json: '_type']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
}

// `for ... := range` loop
struct RangeStmt {
	node_type string                       @[json: '_type']
	key       Ident                        @[json: 'Key']
	value     Ident                        @[json: 'Value']
	tok       string                       @[json: 'Tok']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
	body      BlockStmt                    @[json: 'Body']
}

struct ReturnStmt {
	node_type string @[json: '_type']
	results   []Expr @[json: 'Results']
}

struct SelectorExpr {
	node_type string                       @[json: '_type']
	sel       Ident                        @[json: 'Sel']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
}

struct SendStmt {
	node_type string                       @[json: '_type']
	chan_     &Expr = &Expr(InvalidExpr{}) @[json: 'Chan']
	value     &Expr = &Expr(InvalidExpr{}) @[json: 'Value']
}

struct SliceExpr {
	node_type string                       @[json: '_type']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
	low       &Expr = &Expr(InvalidExpr{}) @[json: 'Low']
	high      &Expr = &Expr(InvalidExpr{}) @[json: 'High']
}

struct StarExpr {
	node_type string                       @[json: '_type']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
}

struct StructType {
	node_type  string    @[json: '_type']
	fields     FieldList @[json: 'Fields']
	incomplete bool      @[json: 'Incomplete']
}

struct SwitchStmt {
	node_type string                       @[json: '_type']
	init      AssignStmt                   @[json: 'Init']
	tag       &Expr = &Expr(InvalidExpr{}) @[json: 'Tag']
	body      BlockStmt                    @[json: 'Body']
}

struct TypeAssertExpr {
	node_type string                       @[json: '_type']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
	typ       &Type = &Type(InvalidExpr{}) @[json: 'Type']
}

struct TypeSpec {
	node_type string                       @[json: '_type']
	name      Ident                        @[json: 'Name']
	params    FieldList                    @[json: 'TypeParams']
	typ       &Type = &Type(InvalidExpr{}) @[json: 'Type']
}

struct TypeSwitchStmt {
	node_type string                       @[json: '_type']
	assign    &Stmt = &Stmt(InvalidStmt{}) @[json: 'Assign'] // Can be AssignStmt or ExprStmt
	// tag       Expr       @[json: 'Tag']
	body BlockStmt @[json: 'Body']
}

struct UnaryExpr {
	node_type string                       @[json: '_type']
	x         &Expr = &Expr(InvalidExpr{}) @[json: 'X']
	op        string                       @[json: 'Op']
}

struct ValueSpec {
	node_type string                       @[json: '_type']
	names     []Ident                      @[json: 'Names']
	typ       &Type = &Type(InvalidExpr{}) @[json: 'Type']
	values    []Expr                       @[json: 'Values']
}

fn parse_go_ast(file_path string) !GoFile {
	data := os.read_file(file_path)!
	return json2.decode[GoFile](data)!
}

fn (e Expr) node_type() string {
	match e {
		InvalidExpr { return 'InvalidExpr' }
		ArrayType { return e.node_type }
		BasicLit { return e.node_type }
		BinaryExpr { return e.node_type }
		CallExpr { return e.node_type }
		ChanType { return e.node_type }
		CompositeLit { return e.node_type }
		Ellipsis { return e.node_type }
		FuncLit { return e.node_type }
		FuncType { return e.node_type }
		Ident { return e.node_type }
		IndexExpr { return e.node_type }
		InterfaceType { return e.node_type }
		KeyValueExpr { return e.node_type }
		MapType { return e.node_type }
		ParenExpr { return e.node_type }
		SelectorExpr { return e.node_type }
		StarExpr { return e.node_type }
		SliceExpr { return e.node_type }
		StructType { return e.node_type }
		TypeAssertExpr { return e.node_type }
		UnaryExpr { return e.node_type }
	}
	return 'unknown node type'
}
