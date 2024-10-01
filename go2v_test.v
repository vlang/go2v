module main

import strings
import os

fn test_all() {
	subdir := 'tests'
	mut app := &App{
		sb: strings.new_builder(1000)
	}

	// All tests
	mut test_names := os.ls('tests') or { return }
	test_names.sort()
	mut tests_failures := []string{}
	for test_name in test_names {
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
			tests_failures << test_name
		}
	}
	if tests_failures.len != 0 {
		eprintln('='.repeat(80))
		eprintln('Found ${tests_failures.len} go2v errors. Use the following commands to reproduce them in isolation:')
		for f in tests_failures {
			eprintln('    ./go2v ${subdir}/${f}')
		}
		exit(1)
	}
}
