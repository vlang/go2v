import os
import v.util.diff

const (
	v_exe     = @VEXE
	go2v_path = @VMODROOT
)

fn test_all() ? {
	os.execute('$v_exe $go2v_path/go2v.v')
	go2v_exe := if os.exists('$go2v_path/go2v.exe') {
		'$go2v_path/go2v.exe'
	} else {
		'$go2v_path/go2v'
	}
	for dir in os.ls('$go2v_path/tests') or { []string{} } {
		os.execute('$go2v_exe $go2v_path/tests/$dir/${dir}.go -o /tests/$dir/out.vv')
		assert diff.color_compare_files(diff.find_working_diff_command() ?, '$go2v_path/tests/$dir/out.vv',
			'$go2v_path/tests/$dir/${dir}.vv').len == 0
	}
}
