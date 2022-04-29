# Special thanks for your interest in contributing, you are more than welcome!

## The translation from Go to V follows those steps:

1. Start the process
   - `go2v.v`
2. Get the Go code (path handling etc.)
	- `transpiler/go2v.v`
3. Generate Go AST
	- `transpiler/ast_getter.go`
	- `transpiler/go2v.v`
4. Parse Go AST
  - `transpiler/ast_parser.v`
5. Transform the parsed Go AST into a V AST struct
   - `transpiler/ast_extractor.v`
6. Adapt remaining Go-ish things to V-ish things
   - `transpiler/ast_transformer.v`
7. Transform the V AST struct into V Code
   - `transpiler/file_writer.v`

## Various tips

- You can get a great overview of the project using `v doc -all -comments transpiler/`.
- If you can't figure out what a piece of code means, remove it and run the test suite; you will be able to figure it out then.

## When adding support for new cases you must add corresponding test(s).

*In this section replace `go2v` with `v run .` or compile Go2V first.*

Tests are located in `tests` subdirectories, each test is composed of a `.go` file, the input, and a `.vv` file containing the expected output.
You can run the test suite using `go2v test` or a specific test using `go2v test test_name`.

- To create a test simply run `go2v test -create test_name`, it'll create a a dummy Go file at `tests/test_name/test_name.go`
- Edit the `.go` file
- You can create the `tests/test_name/test_name.vv` file using `go2v test -out test_name`
