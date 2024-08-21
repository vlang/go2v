// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
import os
import term
import strings

struct App {
mut:
	sb             strings.Builder
	is_fn_call     bool // for lowercase idents
	tests_ok       bool = true
	skip_first_arg bool // for `strings.Replace(s...)` => `s.replace(...)`
	force_upper    bool // for `field Type` in struct decl, `mod.UpperCase` types etc
	type_decl_name string
	is_enum_decl   bool
	is_mut_recv    bool // so that `mut f Foo` is generated instead of `mut f &Foo`
}

fn (mut app App) genln(s string) {
	app.sb.writeln(s)
}

fn (mut app App) gen(s string) {
	app.sb.write_string(s)
}

fn (mut app App) generate_v_code(go_file GoFile) string {
	app.genln('module ${go_file.name.name}\n')

	for decl in go_file.decls {
		match decl.node_type_str {
			// match decl {
			//.gen_decl {
			// GenDecl {
			'GenDecl' {
				app.gen_decl(decl)
			}
			// FuncDecl {
			'FuncDecl' {
				//.func_decl {
				app.func_decl(decl)
			}
			else {
				app.genln('// UNHANDLED decl ${decl}')
			}
		}
	}
	return app.sb.str()
}

fn (mut app App) typ(t Type2) {
	app.force_upper = true
	match t {
		Ident {
			app.gen(go2v_type(t.name))
		}
		ArrayType {
			app.array_type(t)
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
	}
	app.force_upper = false
}

fn type_or_ident(typ TypeOrIdent) string {
	return if typ.elt.name != '' { '[]${typ.elt.name}' } else { typ.name }
}

fn generate_ast_for_go_file(go_file_path string) string {
	output_file := go_file_path + '.json'

	asty_cmd := '${full_path_to_asty} go2json -indent 2 -input ${go_file_path} -output ${output_file}'
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
			println('!!!!!!!!!!!!')
			println(lines0[i])
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
	ensure_asty_is_installed()!

	mut subdir := 'tests'
	mut go_file_name := if os.args.len > 1 { os.args[1] } else { '' }
	mut app := &App{
		sb: strings.new_builder(1000)
	}
	// Not a test
	if go_file_name.ends_with('.go') {
		app.translate_file(go_file_name)
		return
	}
	// A single test
	if go_file_name != '' {
		go_file_name = go_file_name.trim_right('/')
		subdir = os.dir(go_file_name)
		test_name := os.base(go_file_name)
		create_json(subdir, test_name)
		app.run_test(subdir, test_name)!
		return
	}
	// All tests
	mut test_names := os.ls('tests') or { return }
	test_names.sort()
	mut tests_ok := true
	for test_name in test_names {
		println('===========================================')
		create_json(subdir, test_name)
		// A separate instance for each test
		mut app2 := &App{
			sb: strings.new_builder(1000)
		}
		app2.run_test(subdir, test_name) or {
			eprintln('Error running test ${test_name}: ${err}')
			break
		}
		tests_ok &&= app2.tests_ok
	}
	// if !app.tests_ok {
	if tests_ok {
		exit(1)
	}
}
