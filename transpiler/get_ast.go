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

	file_node, err := parser.ParseFile(token.NewFileSet(), flag.Arg(0), nil, parser.ParseComments)
	if err != nil {
		panic(err)
	}

	ast.Fprint(os.Stdout, nil, file_node, ast.NotNilFilter)
}
