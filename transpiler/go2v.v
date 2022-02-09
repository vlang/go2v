module transpiler

import os

// TODO: add a system with a watcher function to make the tree construction stage and possibly other stages concurrent

pub struct Params {
	outputs_file bool
	input_str    string
	input_path   string
	output_path  string = 'out.v'
	go_path      string = 'go'
}

pub fn go_to_v(input_path string, output_path string) ? {
	mut out_path := ''

	if !os.exists(input_path) {
		eprintln("'$input_path' is not a valid file/directory.")
		exit(1)
	}

	is_dir := os.is_dir(input_path)

	// default output directory for directory transpilation
	if output_path == '' && is_dir {
		out_path = 'out'
	}

	mut inputs := []string{}
	mut file_names := []string{}
	if !is_dir {
		inputs << os.read_file(input_path) ?
		file_names << input_path#[..-3] + '.v'
	} else {
		for input in os.ls(input_path) or { []string{} } {
			if input.ends_with('.go') {
				inputs << os.read_file('$input_path/$input') ?
				file_names << input#[..-3] + '.v'
			}
		}
	}

	if output_path == '' && file_names.len > 0 {
		out_path = '.'
	} else if output_path != '' && !is_dir {
		path_separator := $if windows { '\\' } $else { '/' }
		if output_path.contains(path_separator) {
			out_path = output_path.all_before_last(path_separator)
			file_names[0] = output_path.all_after_last(path_separator)
		} else {
			out_path = '.'
			file_names[0] = output_path
		}
	}

	if !is_dir {
		if out_path != '.' && !os.exists(out_path) {
			os.mkdir(out_path) ?
		}
		convert_and_write(inputs.first(), file_names.first(), out_path) ?
	} else {
		os.mkdir(out_path) or {}
		for i, input in inputs {
			convert_and_write(input, file_names[i], out_path) ?
		}
	}
}

pub fn convert_and_write(input string, output_file string, output_path string) ? {
	output := '$output_path/$output_file'
	os.write_file(output, input) ?
	os.execute('go run "${os.resource_abs_path('transpiler')}/get_ast.go" "$output"')

	raw_input := os.read_file(output) ?
	runes_input := raw_input.runes()
	tokens := tokenizer(runes_input)
	tree := tree_constructor(tokens)
	v_ast := ast_constructor(tree)
	v_file := v_file_constructor(v_ast)

	// compile with -cg to enable this block
	// only works properly if converting single file.
	$if debug {
		if os.is_file(output) {
			os.mkdir('temp') or {}
			os.write_file('temp/raw', raw_input) ?
			os.write_file('temp/tokens', tokens.str()) ?
			os.write_file('temp/tree', tree.str()) ?
			os.write_file('temp/ast', v_ast.str()) ?
			os.write_file('temp/file.v', v_file) ?
		}
	}

	os.write_file(output, v_file) ?
}
