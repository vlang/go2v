package main

import (
	"flag"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
)

func main() {
	// parsing flags with none defined just makes input parameters start @ 0
	flag.Parse()
	path := flag.Arg(0)

	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, path, nil, parser.ParseComments)
	if err != nil {
		panic(err)
	}

	f, _ := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0600)
	defer f.Close()

	ast.Fprint(os.Stdout, fset, node, ast.NotNilFilter)
}
