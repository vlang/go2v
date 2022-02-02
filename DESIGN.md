# Go2V

Go2V is a CLI utility to transpile Go source code into V source code.

## Summary / steps

- [x] Get the Go code
	- `go2v.v`
- [x] Get Go AST from Go code
	- `get_ast.go`
	- `go2v.v`
- [x] Tokenise the outputted Go AST
	- `tokenizer.v`
- [x] Pass the tokens into the Go AST tree constructor
	- `tree_constructor.v`
- [ ] Adapt the parsed AST into a sort of V AST
  - `ast_constructor.v`
- [ ] Adapt Go-ish things to V-ish things
  - `ast_constructor.v`
- [ ] Transform the V AST struct into V Code
  - `v_file_constructor.v`
