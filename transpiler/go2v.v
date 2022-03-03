module transpiler

import os
import term
import v.ast
import v.fmt
import v.pref
import v.parser
import v.util

struct InOut {
	input_path  string
	output_path string
}

// TODO: add a system with a watcher function to make the tree construction stage and possibly other stages concurrent

pub fn go_to_v(input_path string, output_path string) ? {
	if !os.exists(input_path) {
		return error('"$input_path" is not a valid file/directory.')
	}

	input_is_dir := os.is_dir(input_path)
	input_is_file := !input_is_dir

	if input_is_file && !input_path.ends_with('.go') {
		return error('"$input_path" is not a `.go` file')
	}

	mut out_path := output_path

	if out_path == '' {
		if input_is_dir {
			out_path = input_path
		} else {
			out_path = '${input_path.all_before_last('.go')}.v'
		}
	} else if out_path.ends_with(os.path_separator) {
		if os.is_file(os.dir(out_path)) {
			return error('"${os.dir(out_path)}" is a file, not a directory')
		}
		out_path = '$out_path${os.file_name(input_path).all_before_last('.go')}.v'
	} else if input_is_file && os.is_dir(out_path) {
		return error('"$input_path" is a file, but "$output_path" is a directory\n' +
			' - add trailing `/` to output if you wish the .v file to be generated in that directory')
	}

	os.mkdir_all(os.dir(out_path)) ?

	if input_is_dir && os.is_file(out_path) {
		return error('"$input_path" is a directory, but "$output_path" is a file')
	}

	mut outputs := []InOut{}

	if input_is_file {
		if input_path.ends_with('.go') {
			outputs << InOut{
				input_path: input_path
				output_path: out_path
			}
		} else {
			return error('"$input_path" is not a `.go` file')
		}
	} else {
		for input in os.walk_ext(input_path, '.go') {
			outputs << InOut{
				input_path: input
				output_path: '$out_path/${os.file_name(input).all_before('.go')}.v'
			}
		}

		if outputs.len == 0 {
			return error('"$input_path" does not contain any `.go` file')
		}
	}

	for inout in outputs {
		convert_and_write(inout.input_path, inout.output_path) ?
	}
}

pub fn convert_and_write(input_path string, output_path string) ? {
	println('converting "$input_path" -> "$output_path"')

	conversion := os.execute('go run "${os.resource_abs_path('transpiler')}/get_ast.go" -- "$input_path"')
	if conversion.exit_code != 0 {
		return error(term.bright_red('"$input_path" is not a valid Go file') +
			'\n==================\n$conversion.output\n==================')
	}

	go_ast := conversion.output
	runes_input := go_ast.runes()
	tokens := tokenizer(runes_input)
	tree := tree_constructor(tokens)
	v_ast := ast_constructor(tree)
	raw_v_file := v_file_constructor(v_ast)

	// compile with -cg to enable this block
	// only works properly if converting single file.
	$if debug {
		os.mkdir('temp') or {}
		os.write_file('temp/go_ast', go_ast) ?
		os.write_file('temp/tokens', tokens.str()) ?
		os.write_file('temp/tree', tree.str()) ?
		os.write_file('temp/v_ast', v_ast.str()) ?
		os.write_file('temp/raw_file.v', raw_v_file) ?
	}

	os.write_file(output_path, raw_v_file) ?

	mut prefs := &pref.Preferences{
		output_mode: .silent
	}
	table := ast.new_table()
	result := parser.parse_text(raw_v_file, output_path, table, .parse_comments, prefs)
	if result.errors.len > 0 {
		for e in result.errors {
			eprintln(util.formatted_error('error:', e.message, output_path, e.pos))
		}
		return error('Generated output could not be formatted:')
	}
	formatted_content := fmt.fmt(result, table, prefs, false)

	// compile with -cg to enable this block
	// only works properly if converting single file.
	$if debug {
		os.write_file('temp/formatted_file.v', formatted_content) ?
	}

	os.write_file(output_path, formatted_content) ?
}
