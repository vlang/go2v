// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module main

import os
import flag
import term
import strings
import v.util.diff

struct App {
mut:
	sb             strings.Builder
	is_fn_call     bool // for lowercase idents
	tests_ok       bool = true
	skip_first_arg bool // for `strings.Replace(s...)` => `s.replace(...)`
	force_upper    bool // for `field Type` in struct decl, `mod.UpperCase` types etc
	type_decl_name string
	is_enum_decl   bool
	is_mut_recv    bool            // so that `mut f Foo` is generated instead of `mut f &Foo`
	cur_fn_names   map[string]bool // for fixing shadowing
}

fn (mut app App) genln(s string) {
	app.sb.writeln(s)
}

fn (mut app App) gen(s string) {
	app.sb.write_string(s)
}

fn (mut app App) generate_v_code(go_file GoFile) string {
	app.genln('module ${app.go2v_ident(go_file.package_name.name)}\n')

	for decl in go_file.decls {
		match decl {
			FuncDecl {
				app.func_decl(decl)
			}
			GenDecl {
				app.gen_decl(decl)
			}
		}
	}
	return app.sb.str()
}

fn (mut app App) typ(t Type) {
	app.force_upper = true
	match t {
		Ident {
			app.gen(go2v_type(t.name))
		}
		ArrayType {
			app.array_type(t)
			// app.gen('[]${t.elt.name}')
		}
		MapType {
			app.map_type(t)
			// app.gen('[]${t.elt.name}')
		}
		StarExpr {
			// Skip & if receiver is mut
			if app.is_mut_recv {
				app.expr(t.x)
				app.is_mut_recv = false
			} else {
				app.star_expr(t)
			}
		}
		SelectorExpr {
			app.selector_expr(t)
		}
		StructType {
			app.gen('STRUCT_TYPE')
		}
		InvalidExpr {
			app.gen('INVALID_EXPR')
		}
		InterfaceType {
			app.interface_type(t)
		}
		FuncType {
			app.func_type(t)
		}
	}
	app.force_upper = false
}

fn generate_ast_for_go_file(go_file_path string) string {
	if !os.exists(go_file_path) {
		eprintln('Missing input .go file: `${go_file_path}`.')
		return ''
	}
	output_file := go_file_path + '.json'

	asty_cmd := '${full_path_to_asty} go2json -comments -indent 2 -input ${go_file_path} -output ${output_file}'
	println('generating ast for ${go_file_path} with\n${asty_cmd}')
	run_result := os.system(asty_cmd)
	if run_result != 0 {
		eprintln('Failed to run asty. Please install it with: `go install github.com/asty-org/asty@latest`.')
		return ''
	}

	json_content := os.read_file(output_file) or {
		eprintln('Failed to read ${output_file}')
		return ''
	}

	// Replace "NodeType": " with "_type": " to handle sum types
	updated_content := json_content.replace('"NodeType": "', '"_type": "')

	os.write_file(output_file, updated_content) or {
		eprintln('Failed to write to ${output_file}')
		return ''
	}
	return output_file
}

fn (mut app App) translate_file(go_file_path string) {
	println('Translating a single Go file ${go_file_path}...')
	ast_file := generate_ast_for_go_file(go_file_path)
	go_file := parse_go_ast(ast_file) or {
		eprintln('Failed to parse Go AST 1: ${err}')
		return
	}
	generated_v_code := app.generate_v_code(go_file)
	v_path := go_file_path.replace('.go', '.v')
	os.write_file(v_path, generated_v_code) or { panic(err) }
	println('${v_path} has been successfully generated')
	os.system('v -translated-go fmt -w ${v_path}')
}

fn (mut app App) run_test(subdir string, test_name string) ! {
	go_file_path := '${subdir}/${test_name}/${test_name}.go.json'
	expected_v_code_path := '${subdir}/${test_name}/${test_name}.vv'

	go_file := parse_go_ast(go_file_path) or {
		eprintln('Failed to parse Go AST 2: ${err}')
		return
	}
	tmpdir := os.temp_dir()
	generated_v_code := app.generate_v_code(go_file)

	v_path := '${tmpdir}/${test_name}.v'
	os.write_file(v_path, generated_v_code) or { panic(err) }
	res := os.execute('v fmt -w ${v_path}')
	if res.exit_code != 0 {
		println(res)
		app.tests_ok = false
	}

	mut formatted_v_code := os.read_file(v_path) or { panic(err) }
	formatted_v_code = formatted_v_code.replace('\n\n\tprint', '\n\tprint') // TODO
	// println('formatted:')
	// println(formatted_v_code)

	expected_v_code := os.read_file(expected_v_code_path) or {
		eprintln('Failed to read expected V code: ${err}')
		return
	}

	println('Running test ${test_name}...')
	// if generated_v_code == expected_v_code {
	// if trim_space(formatted_v_code) == trim_space(expected_v_code) {
	if formatted_v_code == expected_v_code {
		println(term.green('OK'))
	} else {
		println('Test ${test_name} failed.')
		app.tests_ok = false
		println('Generated V code:')
		println(generated_v_code)
		if res.exit_code == 0 {
			println('=======================\nFormatted V code:')
			println(formatted_v_code)
		}
		println('=======================\nExpected V code:')
		println(expected_v_code)
		if res.exit_code == 0 {
			print_diff_line(formatted_v_code, expected_v_code)
			if diff_ := diff.compare_text(expected_v_code, formatted_v_code) {
				println(diff_)
			}
		}
		println('=======================\nGo code:')
		go_code := os.read_file(expected_v_code_path.replace('.vv', '.go')) or { panic(err) }
		println(go_code)
	}
}

fn print_diff_line(formatted_v_code string, expected_v_code string) {
	lines0 := formatted_v_code.split('\n')
	lines1 := expected_v_code.split('\n')
	for i in 0 .. lines0.len {
		if i >= lines1.len {
			return
		}
		if lines0[i].trim_space() != lines1[i].trim_space() {
			println('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
			println(lines0[i])
			println('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^')
			return
		}
	}
}

fn create_json(subdir string, test_name string) {
	input_file := '${subdir}/${test_name}/${test_name}.go'
	// output_file := '${input_file}.json'
	generate_ast_for_go_file(input_file)
}

fn main() {
	mut fp := flag.new_flag_parser(os.args)
	fp.application('go2v')
	fp.version('0.0.1')
	fp.description('go2v is an utility to automatically transpile Go source code into V source code')
	fp.usage_example('file.go')
	fp.usage_example('tests/import_strings')
	fp.footer('\nNormal mode:')
	fp.footer('   Supply the path to a single .go file, that you want translated to V.')
	fp.footer('\nTest folder mode:')
	fp.footer('   The test folder is expected to have 2 files in it - a .go file and a .vv file.')
	fp.footer('   The .go file will be translated, and then the output will be compared to the .vv file.')
	fp.footer('   A failure will be reported, if there are differences.')
	fp.limit_free_args_to_exactly(1)!
	fp.skip_executable()
	mut go_file_name := fp.finalize() or {
		eprintln(err)
		println(fp.usage())
		exit(1)
	}[0]
	ensure_asty_is_installed() or {
		eprintln(err)
		exit(1)
	}

	mut app := &App{
		sb: strings.new_builder(1000)
	}

	if go_file_name.ends_with('.go') {
		if !os.exists(go_file_name) {
			eprintln('go2v error: missing file `${go_file_name}`')
			exit(1)
		}
		app.translate_file(go_file_name)
		return
	}

	mut subdir := 'tests'
	go_file_name = go_file_name.trim_right('/')
	subdir = os.dir(go_file_name)
	test_name := os.base(go_file_name)
	create_json(subdir, test_name)
	app.run_test(subdir, test_name)!
}
