module transpiler

import os

// TODO: add a system with a watcher function to make the tree construction stage and possibly other stages concurrent

pub fn go_to_v(input_path string, output_path string) ? {
	mut out_path := '.'

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
		if input_path.ends_with('.go') {
			inputs << os.read_file(input_path) ?
			file_names << input_path#[..-3] + '.v'
		} else {
			return error('"$input_path" isn\'t a `.go` file')
		}
	} else {
		for input in os.ls(input_path) or { []string{} } {
			if input.ends_with('.go') {
				inputs << os.read_file('$input_path/$input') ?
				file_names << input#[..-3] + '.v'
			}
		}
		if inputs.len == 0 {
			return error('"$input_path" doesn\'t contain any `.go` file')
		}
	}

	if output_path != '' {
		if os.exists(output_path) {
			if is_dir && !os.is_dir(output_path) {
				return error('"$input_path" is a directory, but "$output_path" is not')
			}
		}

		path_separator := $if windows { '\\' } $else { '/' }
		if output_path.contains(path_separator) {
			if !is_dir {
				out_path = output_path.all_before_last(path_separator)
				if !output_path.ends_with('/') {
					file_names[0] = output_path.all_after_last(path_separator)
				}
			} else {
				out_path = output_path
			}
		} else {
			if !is_dir {
				file_names[0] = output_path
			} else {
				out_path = output_path
			}
		}
	}

	if !is_dir {
		if out_path != '.' {
			if !os.exists(out_path) {
				os.mkdir_all(out_path) ?
			} else if os.is_file(out_path) {
				return error('"$out_path" is a file, not a directory')
			}
		}
		convert_and_write(inputs.first(), file_names.first(), out_path) ?
	} else {
		os.mkdir_all(out_path) ?
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
