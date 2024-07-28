// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
import os
import term
import strings

// const nr_tests = 15

const passing_tests = [
	'struct_simple',
	'method',
	'operators',
	'fn_call',
	'fn_case',
	'append',
	'for_c_style_inc',
	'for_in',
	'operation',
	'match',
	'arrays',
	'math_expr',
	'if',
	'if_complex_condition',
	'if_else_if',
	'array',
	'array_byte',
]

struct App {
mut:
	sb         strings.Builder
	is_fn_call bool // for lowercase idents
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

fn (app &App) type_or_ident(typ TypeOrIdent) string {
	return if typ.elt.name != '' { '[]${typ.elt.name}' } else { typ.name }
}

fn (mut app App) run_test(test_name string) ! {
	go_file_path := 'tests/${test_name}/${test_name}.go.json'
	expected_v_code_path := 'tests/${test_name}/${test_name}.vv'

	go_file := parse_go_ast(go_file_path) or {
		eprintln('Failed to parse Go AST: ${err}')
		return
	}

	tmpdir := os.temp_dir()

	generated_v_code := app.generate_v_code(go_file)

	v_path := tmpdir + '/${test_name}.v'
	os.write_file(v_path, generated_v_code) or { panic(err) }
	res := os.execute('v fmt -w ${v_path}')
	if res.exit_code != 0 {
		// println(res)
	}

	formatted_v_code := os.read_file(v_path) or { panic(err) }
	// println('formatted:')
	// println(formatted_v_code)

	expected_v_code := os.read_file(expected_v_code_path) or {
		eprintln('Failed to read expected V code: ${err}')
		return
	}

	println('Running test ${test_name}...')
	// if generated_v_code == expected_v_code {
	if formatted_v_code == expected_v_code {
		println(term.green('OK'))
	} else {
		println('Test ${test_name} failed.')
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

fn main() {
	go_file_name := if os.args.len > 1 { os.args[1] } else { '' }
	mut app := &App{
		sb: strings.new_builder(1000)
	}
	if go_file_name != '' {
		app.run_test(go_file_name)!
		return
	}
	test_names := os.ls('tests') or { return }
	//.filter(it.ends_with('.go'))
	//.map(it.replace('.go', ''))

	// test_names.sort(it.split('.')[0]

	for test_name in test_names {
		if test_name !in passing_tests {
			continue
		}
		// println(test_name)
		if !os.exists('tests/${test_name}/${test_name}.go.json') {
			println('generating ast for ${test_name}')
			os.system('asty go2json -indent 2 -input tests/${test_name}/${test_name}.go -output tests/${test_name}/${test_name}.go.json')

			continue
		}
		// Extract the number before the first dot
		// test_number_str := test_name.before('.')
		// test_number := test_number_str.int()

		// Continue if the number is greater than what we need
		// if test_number > nr_tests {
		// continue
		//}
		// for test_name in test_names {
		println('===========================================')

		app.run_test(test_name) or {
			eprintln('Error running test ${test_name}: ${err}')
			break
		}
	}
}
