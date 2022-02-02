module main

import os
import cli
import transpiler

fn main() {
	mut app := cli.Command{
		name: 'go2v'
		description: 'Go2V is a CLI utility to transpile Go source code into V source code.'
		execute: fn (cmd cli.Command) ? {
			if cmd.args.len == 0 { println('Wrong usage, see "go2v help"') } else { transpiler.go_to_v(cmd.args[0], cmd.args[2] or {
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
				execute: fn (cmd cli.Command) ? {
					mut stats := ''
					if cmd.args.len == 0 {
						stats = '-stats'
					} else if cmd.args[0] == '-compact' {
						stats = ''
					} else {
						println('Wrong usage, see "go2v help test"')
						return
					}

					os.execvp('${@VEXE}', [stats, 'test', os.resource_abs_path('/tests')]) ?
					return
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}
