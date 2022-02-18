# Go2V

Go2V is a CLI utility to transpile Go source code into V source code.

## Summary / steps

- [x] Get the Go code
	- `go2v.v`
- [x] Generate Go AST
	- `get_ast.go`
	- `go2v.v`
- [x] Tokenise the Go AST
	- `tokenizer.v`
- [x] Pass the tokens into the Go AST tree constructor
	- `tree_constructor.v`
- [x] Adapt the parsed AST into a sort of V AST
  - `ast_constructor.v`
- [x] Adapt remaining Go-ish things to V-ish things
  - `v_style.v`
- [x] Transform the V AST struct into V Code
  - `v_file_constructor.v`
