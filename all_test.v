import os
import term
import v.util.diff

const (
	go2v_path = @VMODROOT
	go2v_exe  = prepare_go2v_executable()
	diffcmd   = diff.find_working_diff_command()?
)

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
	mut all_tests := os.ls('$go2v_path/tests') or { []string{} }
	all_tests.sort()
	mut failures := []string{}

	for tidx, dir in all_tests {
		start := '${tidx + 1:3}/${all_tests.len:-2}'

		produced_vv_source := os.join_path(os.temp_dir(), 'out.vv')

		common_relative_path := 'tests/$dir/$dir'
		relative_expected_vv_source := '${common_relative_path}.vv' // `relative/path/to/test_name.vv`
		go_source := os.join_path(go2v_path, common_relative_path) + '.go' // `path/to/test_name.go`
		expected_vv_source := os.join_path(go2v_path, relative_expected_vv_source)
		full_conversion_command := '$go2v_exe ${os.quoted_path(go_source)} -o ${os.quoted_path(produced_vv_source)}'
		res := os.execute(full_conversion_command)

		// missing .go file
		if !os.exists(go_source) {
			println('${term.bright_magenta('SKIP  ')} $start `$go_source` is missing.')
			continue
		}

		// Invalid Go code
		if res.exit_code != 0 {
			failures << full_conversion_command
			println('${term.bright_red('failed')} $start $relative_expected_vv_source . go2v exited with $res.exit_code code; output:\n$res.output')
			continue
		}
		// `test_name.vv` file missing
		if !os.exists(expected_vv_source) {
			failures << full_conversion_command
			println('${term.bright_red('failed')} $start $relative_expected_vv_source . $expected_vv_source is missing.')
			continue
		}
		// `out.vv` file missing
		if !os.exists(produced_vv_source) {
			failures << full_conversion_command
			println('${term.bright_red('failed')} $start $relative_expected_vv_source . $produced_vv_source is missing.')
			continue
		}
		// Go2V generated wrong output
		if os.read_file(produced_vv_source)? != os.read_file(expected_vv_source)? {
			failures << full_conversion_command
			println('${term.bright_red('failed')} $start $relative_expected_vv_source')
			println(diff.color_compare_files(diffcmd, expected_vv_source, produced_vv_source))
			continue
		}

		println('${term.bright_green('passed')} $start $relative_expected_vv_source')
		assert true
	}

	if failures.len > 0 {
		eprintln('Summary of test failures:')
		for f in failures {
			eprintln('${term.bright_red('failed')}: $f')
		}
		exit(1)
	}
}
