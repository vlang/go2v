import os
import v.util.diff

// full path to the V compiler (injected by V itself)
const vexe = @VEXE

const qvexe = os.quoted_path(vexe) // qvexe should be used inside os.execute, to avoid problems with unquoted paths with spaces/!/# etc.

const myfolder = os.dir(@FILE) // the folder where this file is, can be used as an anchor for locating other resources.

const diff_cmd = diff.find_working_diff_command() ? // can be used to find differences between text files

const tfolder = os.join_path(os.temp_dir(), 'go2v_functional') // write all temporary files for the tests here

const test_g2v = os.join_path(tfolder, 't_go2v') // full path to the *tested* executable.

const qtest_g2v = os.quoted_path(test_g2v) // qtest_g2v should be used inside os.execute, because the command is passed to a shell

fn testsuite_begin() {
	os.mkdir_all(tfolder) or {}
}

fn testsuite_end() {
	os.rmdir_all(tfolder) or {}
}

fn test_v_works() {
	res := os.execute('$qvexe version')
	assert res.exit_code == 0
	assert res.output.starts_with('V ')
	// dump(vexe)
	// dump(qvexe)
	// dump(myfolder)
	// dump(diff_cmd)
	// dump(tfolder)
}

fn test_go2v_compiles() {
	res := os.execute('$qvexe -o $test_g2v .')
	assert res.exit_code == 0
}

fn test_go2v_works() {
	dump(qtest_g2v)
	res := os.execute('$qtest_g2v --version')
	println(res)
	// assert res.exit_code == 0
	// assert res.output != ''
}

// Add more qvexe or qtest_g2v compilations/runs ...
// You can also use:
//    diff := diff.color_compare_files(diff_cmd, file, formatted_file_path)
//    if diff.len > 0 { ... }
