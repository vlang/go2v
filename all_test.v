import os
import term

const (
	go2v_path = @VMODROOT
)

fn test_all() ? {
	os.execute('${@VEXE} $go2v_path/go2v.v')
	go2v_exe := if os.exists('$go2v_path/go2v.exe') {
		'$go2v_path/go2v.exe'
	} else {
		'$go2v_path/go2v'
	}
	for dir in os.ls('$go2v_path/tests') or { []string{} } {
		os.execute('$go2v_exe $go2v_path/tests/$dir/${dir}.go -o $go2v_path/tests/$dir/out.vv')
		assert os.read_file('$go2v_path/tests/$dir/out.vv') ? == os.read_file('$go2v_path/tests/$dir/${dir}.vv') ?
		println('$dir test ${term.bright_green('passed')}')
	}
}
