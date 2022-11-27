package main

import (
	"flag"
	"go/ast"
	"go/parser"
	"go/token"
	"os"
)

func main() {
	flag.Parse()

	file, err := parser.ParseFile(token.NewFileSet(), flag.Arg(0), nil, parser.ParseComments)
	if err != nil {
		panic(err)
	}

	_ = ast.Fprint(os.Stdout, nil, file, ast.NotNilFilter)
}
