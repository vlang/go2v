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
	sb                      strings.Builder
	is_fn_call              bool // for lowercase idents
	tests_ok                bool = true
	skip_first_arg          bool // for `strings.Replace(s...)` => `s.replace(...)`
	skip_call_parens        bool // skip generating () and args for fully-handled calls
	force_upper             bool // for `field Type` in struct decl, `mod.UpperCase` types etc
	no_star                 bool // To skip & in StarExpr in type matches  (interfaces)
	type_decl_name          string
	is_enum_decl            bool
	is_mut_recv             bool              // so that `mut f Foo` is generated instead of `mut f &Foo`
	in_go_stmt              bool              // inside a go statement (don't convert IIFE to block)
	in_defer_block          bool              // inside a defer block (return not allowed)
	in_interface_decl       bool              // inside an interface declaration (skip fn prefix)
	cur_fn_names            map[string]bool   // for fixing shadowing
	name_mapping            map[string]string // Go name to V name mapping for renamed variables
	running_test            bool              // disables shadowing for now
	struct_or_alias         []string          // skip camel_to_snake for these, but force capitalize
	named_return_params     map[string]bool   // for named return parameters like `func foo() (im int)`
	named_return_types      map[string]Type   // types for named return parameters
	pending_named_returns   bool              // true when entering function body, need to declare named returns
	global_names            map[string]bool   // track all global names (functions, structs, etc.) to avoid collisions
	inline_struct_count     int               // counter for generating unique inline struct names
	temp_var_count          int               // counter for generating unique temp variable names
	pending_structs         []string          // inline struct definitions to output
	enum_types              map[string]bool   // types that will become enums (detected by pre-scan)
	enum_values             map[string]bool   // enum constant values (for adding . prefix in match)
	array_type_aliases      map[string]bool   // type aliases to array types (for correct composite lit handling)
	struct_types            map[string]bool   // declared struct type names (for map key compatibility handling)
	map_string_key_vars     map[string]bool   // map vars whose keys are translated to string
	fmt_needs_closing_paren bool              // for wrapping printf in print(strconv.v_sprintf(...))
	at_stmt_level           bool              // true when we can safely emit temp var declarations
	error_vars              map[string]bool   // variables that hold error/option types (for nil -> none translation)
	first_arg_needs_mut     bool              // for binary.PutUint* functions where first arg needs mut
	current_iota_value      int               // current iota value in const block (starts at 0)
	in_const_block          bool              // true when processing a const block
	last_const_expr         Expr              // last expression in const block (for iota pattern reuse)
	call_arg_temp_vars      map[string]string // temp vars for module-qualified composite lits in call args
	current_call_rhs_idx    int               // current RHS index being processed in assignment
	in_unsafe_block         bool              // true when generating inside unsafe {} block
	imported_modules        map[string]bool   // track already imported modules to avoid duplicates
	required_imports        map[string]bool   // imports required based on actual code usage (added at end)
	pending_sum_types       []string          // sum type declarations to insert before functions
	pending_sum_type_names  map[string]string // maps elem-type signature to sum type name
}

fn (mut app App) genln(s string) {
	app.sb.writeln(s)
}

fn (mut app App) gen(s string) {
	app.sb.write_string(s)
}

// require_import marks a module as required based on actual code usage
fn (mut app App) require_import(mod string) {
	app.required_imports[mod] = true
}

fn (mut app App) generate_v_code(go_file GoFile) string {
	// Pre-scan to identify enum types (types used with iota in const blocks)
	app.scan_for_enum_types(go_file.decls)
	// Pre-scan type names so forward references in function signatures/conversions
	// are treated as types even when declarations appear later in the file.
	app.scan_for_type_names(go_file.decls)

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

	// Output any pending inline struct definitions
	for struct_def in app.pending_structs {
		app.gen(struct_def)
	}

	mut result := app.sb.str()

	// Insert required imports that were discovered during code generation
	if app.required_imports.len > 0 {
		mut imports_str := ''
		for imp, _ in app.required_imports {
			if imp !in app.imported_modules {
				imports_str += 'import ${imp}\n'
			}
		}
		if imports_str != '' {
			// Find the end of the module line and insert imports there
			if idx := result.index('\n\n') {
				result = result[..idx + 1] + imports_str + result[idx + 1..]
			}
		}
	}

	// Insert pending sum type declarations before the first function
	if app.pending_sum_types.len > 0 {
		mut sum_types_str := ''
		for decl in app.pending_sum_types {
			sum_types_str += decl
		}
		if idx := result.index('\nfn ') {
			result = result[..idx + 1] + sum_types_str + '\n' + result[idx + 1..]
		}
	}

	return result
}

fn (mut app App) scan_for_type_names(decls []Decls) {
	for decl in decls {
		if decl is GenDecl && decl.tok == 'type' {
			for spec in decl.specs {
				if spec is TypeSpec {
					name := spec.name.name
					if name == '' {
						continue
					}
					mut v_name := name.capitalize()
					if v_name.len == 1 {
						v_name += v_name
					}
					if name !in app.struct_or_alias {
						app.struct_or_alias << name
					}
					if v_name !in app.struct_or_alias {
						app.struct_or_alias << v_name
					}
					if spec.typ is StructType {
						app.struct_types[name] = true
						app.struct_types[v_name] = true
					}
				}
			}
		}
	}
}

// scan_for_enum_types pre-scans declarations to identify types that will become enums
// and their values. This allows type_decl to skip generating type aliases for these types
// and allows enum values to be prefixed with . when used in switch/match expressions
fn (mut app App) scan_for_enum_types(decls []Decls) {
	for decl in decls {
		if decl is GenDecl {
			if decl.tok == 'const' {
				// Track if we're in an enum block
				mut in_enum_block := false
				for spec in decl.specs {
					if spec is ValueSpec {
						// Check if this const starts an enum (uses iota but not bitflag)
						if spec.values.len > 0 {
							first_val := spec.values[0]
							if app.contains_iota(first_val) && !app.is_bitflag_pattern(first_val) {
								in_enum_block = true
								// Record the type name
								if spec.typ is Ident {
									ident := spec.typ as Ident
									if ident.name != '' {
										app.enum_types[ident.name] = true
									}
								}
							}
						}
						// If we're in an enum block, track all const names as enum values
						if in_enum_block {
							for name in spec.names {
								v_name := app.go2v_ident(name.name)
								app.enum_values[v_name] = true
							}
						}
					}
				}
			}
		}
	}
}

fn (mut app App) typ(t Type) {
	app.force_upper = true
	match t {
		Ident {
			// Check if it's a basic type
			conversion := go2v_type_checked(t.name)
			if conversion.is_basic {
				// It's a basic type, use the converted value directly
				app.gen(conversion.v_type)
			} else {
				// It's a custom type, use go2v_ident for struct/alias handling
				app.gen(app.go2v_ident(t.name))
			}
		}
		ArrayType {
			app.array_type(t)
		}
		ChanType {
			app.chan_type(t)
		}
		Ellipsis {
			// Variadic parameter: ...T in Go => ...T in V
			app.gen('...')
			conversion := go2v_type_checked(t.elt.name)
			if conversion.is_basic {
				app.gen(conversion.v_type)
			} else {
				app.gen(app.go2v_ident(t.elt.name))
			}
		}
		MapType {
			app.map_type(t)
		}
		StarExpr {
			// Skip & if receiver is mut
			if app.is_mut_recv {
				app.expr(t.x)
				app.is_mut_recv = false
			} else {
				// V arrays are already references, so *[]T becomes just []T
				if t.x is ArrayType {
					app.array_type(t.x)
				} else {
					app.star_expr(t)
				}
			}
		}
		SelectorExpr {
			app.selector_expr(t)
		}
		StructType {
			app.struct_type(t)
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

	asty_cmd := '${full_path_to_asty} go2json -imports -comments -indent 2 -input ${go_file_path} -output ${output_file}'
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
	v_path := go_file_path.substr_ni(0, -3) + '.v'
	os.write_file(v_path, generated_v_code) or { panic(err) }
	println('${v_path} has been successfully generated')
	// Note: Skipping vfmt to preserve space before { in module-qualified struct literals
	// This works around a V parser issue where api.Type{ inside function args fails
	// but api.Type { (with space) works. Unfortunately vfmt removes the space.
	// res := os.system('v -translated-go fmt -w ${v_path}')
	// if res != 0 {
	// 	exit(1)
	// }
}

fn (mut app App) run_test(subdir string, test_name string) ! {
	app.running_test = true
	go_file_path := '${subdir}/${test_name}/${test_name}.go.json'
	is_complex_test := subdir.starts_with('complex_tests')

	go_file := parse_go_ast(go_file_path) or {
		eprintln('Failed to parse Go AST 2: ${err}')
		return
	}
	tmpdir := os.temp_dir()
	generated_v_code := app.generate_v_code(go_file)

	v_path := '${tmpdir}/${test_name}.v'
	os.write_file(v_path, generated_v_code) or { panic(err) }
	res := os.execute('v -translated-go fmt -w ${v_path}')
	if res.exit_code != 0 {
		println(res)
		app.tests_ok = false
	}

	println('Running test ${test_name}...')

	// For complex tests, just verify that translation and vfmt succeeded
	if is_complex_test {
		if res.exit_code == 0 {
			println(term.green('OK (translation + vfmt)'))
		} else {
			println('Test ${test_name} failed: vfmt returned non-zero exit code')
			app.tests_ok = false
		}
		return
	}

	// For simple tests, compare against .vv file
	expected_v_code_path := '${subdir}/${test_name}/${test_name}.vv'

	mut formatted_v_code := os.read_file(v_path) or { panic(err) }

	expected_v_code := os.read_file(expected_v_code_path) or {
		eprintln('Failed to read expected V code: ${err}')
		return
	}

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
