import os

// TODO: add a system with a watcher function to make the tree construction stage concurrent and possibly also to the other stages

struct Params {
	outputs_file bool
	input_str    string
	input_path   string
	output_path  string = 'out.v'
	go_path      string = 'go'
}

// TODO TEMP REMOVE
fn main() {
	go_to_v(Params{
		input_path: 'test.go'
		// outputs_file: true
	}) ?
}

pub fn go_to_v(options Params) ?string {
	if !os.exists_in_system_path('go') {
		// TODO: better error message
		panic("Go is needed by the utility and it isn't installed or not present in your path, get it at https://golang.org or manually specify the path to the go binary by passing the --go-path parameter if using the CLI or the {go_path} parameter in the function call")
	}

	mut str := ''
	mut had_to_create_a_file := false
	mut input_path := options.input_path

	if options.input_path == '' && options.input_str == '' {
		panic('Either the input_path or input_str parameter must be set')
	} else if options.input_path != '' && options.input_str != '' {
		panic('Only one of the input_path or input_str parameter must be set')
	} else if options.input_path != '' {
		str = os.read_file(options.input_path) ?
	} else {
		str = options.input_str
		input_path = 'temp'
		had_to_create_a_file = true
		os.write_file('temp', str) ?
	}

	os.execute('$options.go_path run ${os.resource_abs_path('/')}/get_ast.go -f $input_path -o $options.output_path')
	raw_input := os.read_file(options.output_path) ?
	os.rm(options.output_path) ?
	if had_to_create_a_file {
		os.rm(input_path) ?
	}

	input := raw_input.runes()
	tokens := tokenizer(input)
	tree := tree_constructor(tokens)
	v_ast := ast_constructor(tree)
	v_file := v_file_constructor(v_ast)

	if options.outputs_file {
		os.write_file(options.output_path, v_file) ?
	}

	// TODO TEMP REMOVE
	os.mkdir('test') or {}
	os.write_file('test/tree', tree.str()) ?
	os.write_file('test/ast', v_ast.str()) ?
	os.write_file('test/file.v', v_file) ?

	return v_file
}
