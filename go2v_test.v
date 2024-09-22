module main

import strings
import os

fn test_all() {
	mut subdir := 'tests'
	mut app := &App{
		sb: strings.new_builder(1000)
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
	if !tests_ok {
		exit(1)
	}
}
