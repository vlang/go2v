import os
import term
import v.util.diff

const go2v_path = @VMODROOT

fn prepare_go2v_executable() string {
	go2v_source := '$go2v_path/go2v.v'
	go2v_executable := if os.user_os() == 'windows' {
		'$go2v_path/go2v.exe'
	} else {
		'$go2v_path/go2v'
	}
	if !os.exists(go2v_executable) {
		os.execute('${os.quoted_path(@VEXE)} -o ${os.quoted_path(go2v_executable)} ${os.quoted_path(go2v_source)}')
	}
	return os.quoted_path(go2v_executable)
}

fn test_all() ? {
	all_tests := os.ls('$go2v_path/tests') or { []string{} }
	mut failures := []string{}

	for tidx, dir in all_tests {
		start := '${tidx + 1:2}/${all_tests.len:-2}'
		go_source := os.quoted_path('$go2v_path/tests/$dir/${dir}.go')
		produced_vv_source := '$go2v_path/tests/$dir/out.vv'
		expected_vv_source := '$go2v_path/tests/$dir/${dir}.vv'
		res := os.execute('$prepare_go2v_executable() $go_source -o ${os.quoted_path(produced_vv_source)}')

		// Invalid Go code
		if res.exit_code != 0 {
			failures << dir
			println('${term.bright_red('failed')} $start $dir . go2v exited with $res.exit_code code; output:\n$res.output')
			continue
		}
		// `test_name.vv` file missing
		if !os.exists(expected_vv_source) {
			failures << dir
			println('${term.bright_red('failed')} $start $dir . $expected_vv_source is missing.')
			continue
		}
		// `out.vv` file missing
		if !os.exists(produced_vv_source) {
			failures << dir
			println('${term.bright_red('failed')} $start $dir . $produced_vv_source is missing.')
			continue
		}
		// Go2V generated wrong output
		if os.read_file(produced_vv_source) ? != os.read_file(expected_vv_source) ? {
			failures << dir
			println('${term.bright_red('failed')} $start $dir')
			println(diff.color_compare_files(diff.find_working_diff_command() ?, expected_vv_source,
				produced_vv_source))
			continue
		}

		println('${term.bright_green('passed')} $start $dir')
		assert true
	}

	if failures.len > 0 {
		eprintln('Summary of test failures:')
		for f in failures {
			eprintln('> Failed test(s): $f')
		}
		exit(1)
	}
}
