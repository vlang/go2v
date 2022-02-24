# Special thanks for your interest in contributing, you are more than welcome!

## The translation from Go to V follows those steps:

1. Start the process
   - `go2v.v`
2. Get the Go code (path handling etc.)
	- `transpiler/go2v.v`
3. Generate Go AST
	- `transpiler/get_ast.go`
	- `transpiler/go2v.v`
4. Parse Go AST
   - Tokenize Go AST
      - `transpiler/tokenizer.v`
   - Transform the list of tokens into a tree
      - `transpiler/tree_constructor.v`
5. Transform the parsed Go AST into a V AST struct
   - `transpiler/ast_constructor.v`
   - `transpiler/utils.v`
6. Adapt remaining Go-ish things to V-ish things
   - `transpiler/v_style.v`
7. Transform the V AST struct into V Code
   - `transpiler/v_file_constructor.v`

## When adding support for new cases you must add corresponding test(s).

*In this section replace `go2v` with `v run .` or compile Go2V first.*

Tests are located in `tests` subdirectories, each test is composed of a `.go` file, the input, and a `.vv` file containing the expected output.
You can run the test suite using `go2v test` or a specific test using `go2v test test_name`.

- To create a test simply run `go2v test -create test_name`, it'll create a a dummy Go file at `tests/test_name/test_name.go`
- Edit the `.go` file
- You can create the `tests/test_name/test_name.vv` file using `go2v test -out test_name`
