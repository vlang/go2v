module main

import os
import cli
import transpiler

const (
	go2v_path = @VMODROOT
)

fn main() {
	mut app := cli.Command{
		name: 'go2v'
		flags: [
			cli.Flag{
				flag: .bool
				name: 'help'
				abbrev: 'h'
			},
		]
		description: 'Go2V is a CLI utility to transpile Go source code into V source code.'
		execute: fn (cmd cli.Command) ? {
			if cmd.args.len == 0 { println('At least one file or directory must be given, see "go2v help"') } else { transpiler.go_to_v(cmd.args[0], cmd.args[2] or {
					''}) ? }
			return
		}
		commands: [
			cli.Command{
				name: 'help'
				execute: fn (cmd cli.Command) ? {
					help_topic := cmd.args[0] or { 'help' }
					println(os.read_file(os.resource_abs_path('/help/${help_topic}.txt')) or {
						'No help topic for $help_topic'
					})
					return
				}
			},
			cli.Command{
				name: 'test'
				flags: [
					cli.Flag{
						flag: .bool
						name: 'compact'
						description: 'do not output build stats'
					},
					cli.Flag{
						flag: .string
						name: 'create'
						description: 'create new test'
					},
					cli.Flag{
						flag: .string
						name: 'out'
						description: 'save output of test'
					},
				]
				execute: fn (cmd cli.Command) ? {
					compact := cmd.flags.get_bool('compact') ?
					create := cmd.flags.get_string('create') ?
					out := cmd.flags.get_string('out') ?
					test_to_run := if cmd.args.len > 0 { cmd.args[0] } else { '.' }
					if create != '' && out != '' {
						println('Cannot use -create and -out at the same time')
						return
					}

					if create != '' {
						if os.exists('$go2v_path/tests/$create') {
							println('$go2v_path/tests/$create already exists - remove it if you want to create a new test with the same name')
							return
						}
						os.mkdir('$go2v_path/tests/$create') ?
						os.write_file('$go2v_path/tests/$create/${create}.go', 'package main\n\nfunc main() {\n\t\n}\n') ?
						println('$go2v_path/tests/$create/${create}.go created')
					} else if out != '' {
						if os.is_dir('$go2v_path/tests/$out/${out}.vv') {
							println('$go2v_path/tests/$out/${out}.vv is a directory - remove it before trying to save output')
							return
						}
						transpiler.go_to_v('$go2v_path/tests/$out/${out}.go', '$go2v_path/tests/$out/${out}.vv') ?
					} else if compact {
						os.execvp('${@VEXE}', [
							'test',
							os.resource_abs_path(test_to_run),
						]) ?
					} else {
						os.execvp('${@VEXE}', [
							'-stats',
							'test',
							'${os.resource_abs_path(test_to_run)}/all_test.v',
						]) ?
					}
					return
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}
