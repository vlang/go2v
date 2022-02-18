package main

import (
	"go/ast"
	"go/parser"
	"go/token"
	"os"
)

func main() {
	path := os.Args[1]

	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, path, nil, parser.ParseComments)
	if err != nil {
		panic(err)
	}

	f, _ := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0600)
	defer f.Close()

	ast.Fprint(f, fset, node, ast.NotNilFilter)
}
