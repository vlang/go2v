module main

import strings
import os

fn test_all() {
	mut app := &App{
		sb: strings.new_builder(1000)
	}

	// All tests
	mut tests_to_run := map[string][]string{}
	mut tests_failures := []string{}

	mut test_names := os.ls('tests') or { return }
	test_names.sort()
	tests_to_run['tests'] = test_names

	// mut complex_names := os.ls('complex_tests/esbuild') or { return }
	// if complex_names.len > 0 {
	// 	complex_names.sort()
	// 	tests_to_run['complex_tests/esbuild'] = complex_names
	// }

	for subdir, tests in tests_to_run {
		for test_name in tests {
			println('='.repeat(44))
			create_json(subdir, test_name)
			// A separate instance for each test
			mut app2 := &App{
				sb: strings.new_builder(1000)
			}
			app2.run_test(subdir, test_name) or {
				eprintln('Error running test ${test_name}: ${err}')
				exit(1)
			}
			if !app2.tests_ok {
				tests_failures << '${subdir}/${test_name}'
			}
		}
	}

	if tests_failures.len != 0 {
		eprintln('='.repeat(80))
		eprintln('Found ${tests_failures.len} go2v errors. Use the following commands to reproduce them in isolation:')
		for f in tests_failures {
			eprintln('    ./go2v ${f}')
		}
		exit(1)
	}
}
