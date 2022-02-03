module transpiler

import os

// TODO: add a system with a watcher function to make the tree construction stage concurrent and possibly also to the other stages

pub struct Params {
	outputs_file bool
	input_str    string
	input_path   string
	output_path  string = 'out.v'
	go_path      string = 'go'
}

pub fn go_to_v(input_path string, output_path string) ? {
	mut out_path := output_path

	if !os.exists(input_path) {
		panic("The input file/directory doesn't exist.")
	}

	is_dir := os.is_dir(input_path)

	// default output directory for directory transpilation
	if output_path == '' && is_dir {
		out_path = 'out'
	}

	mut inputs := []string{}
	mut files_name := []string{}
	if !is_dir {
		inputs << os.read_file(input_path) ?
		files_name << input_path#[..-3] + '.v'
	} else {
		for input in os.ls(input_path) or { []string{} } {
			if input.ends_with('.go') {
				inputs << os.read_file('$os.getwd()/$input_path/$input') ?
				files_name << input#[..-3] + '.v'
			}
		}
	}

	// custom output file for file transpilation
	if out_path != '' && !is_dir {
		files_name[0] = out_path
		out_path = '.'
	}

	if !is_dir {
		convert_and_write(inputs.first(), files_name.first(), out_path) ?
	} else {
		os.mkdir(out_path) or {}
		for i, input in inputs {
			convert_and_write(input, files_name[i], out_path) ?
		}
	}
}

fn convert_and_write(input string, output_file string, output_path string) ? {
	output := '$os.getwd()/$output_path/$output_file'
	os.write_file(output, input) ?
	os.execute('go run "${os.resource_abs_path('transpiler')}/get_ast.go" "$output"')

	raw_input := os.read_file(output) ?
	runes_input := raw_input.runes()
	tokens := tokenizer(runes_input)
	tree := tree_constructor(tokens)
	v_ast := ast_constructor(tree)
	v_file := v_file_constructor(v_ast)

	// TODO TEMP REMOVE / USE THIS FOR DEBUGGING
	/*
	os.mkdir('temp') or {}
	os.write_file('temp/tree', tree.str()) ?
	os.write_file('temp/ast', v_ast.str()) ?
	os.write_file('temp/file.v', v_file) ?
	*/

	os.write_file(output, v_file) ?
}
