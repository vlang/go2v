import os

const (
	hello_go              = 'package main\n\nimport "fmt"\n\nfunc main() {\n\tfmt.Println("hello")\n}\n'
	go2v_path             = @VMODROOT
	go2v_exe              = prepare_go2v_executable()
	path_test_area        = os.join_path_single(go2v_path, 'path_test_area')
	go_test_file          = os.join_path_single(path_test_area, 'hello.go')
	quoted_go_test_file   = os.quoted_path(go_test_file)
	quoted_path_test_area = os.quoted_path(path_test_area)
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

fn testsuite_begin() {
	os.mkdir_all(path_test_area)!
	os.write_file(go_test_file, hello_go)!
}

fn testsuite_end() {
	os.rmdir_all(path_test_area)!
}

fn test_file_in_with_no_out() {
	res := os.execute('$go2v_exe $quoted_go_test_file')
	assert res.exit_code == 0
	paths := os.ls(path_test_area)!
	assert 'hello.v' in paths
	os.rm(os.join_path_single(path_test_area, 'hello.v'))!
}

fn test_file_in_with_file_out() {
	res := os.execute('$go2v_exe $quoted_go_test_file -o ${os.quoted_path(os.join_path_single(path_test_area,
		'foo'))}')
	assert res.exit_code == 0
	paths := os.ls(path_test_area)!
	assert 'foo' in paths
	os.rm(os.join_path_single(path_test_area, 'foo'))!
}

fn test_file_in_with_dir_out() {
	res := os.execute('$go2v_exe $quoted_go_test_file -o $quoted_path_test_area')
	assert res.exit_code != 0
	paths := os.ls(path_test_area)!
	assert 'hello.v' !in paths
}

fn test_file_in_with_file_with_slash_out() {
	res := os.execute('$go2v_exe $quoted_go_test_file -o ${os.quoted_path(go_test_file +
		os.path_separator)}')
	assert res.exit_code != 0
	paths := os.ls(path_test_area)!
	assert 'hello.v' !in paths
}

fn test_file_in_with_dir_with_slash_out() {
	res := os.execute('$go2v_exe $quoted_go_test_file -o ${os.quoted_path(path_test_area +
		os.path_separator)}')
	assert res.exit_code == 0
	paths := os.ls(path_test_area)!
	assert 'hello.v' in paths
	os.rm(os.join_path_single(path_test_area, 'hello.v'))!
}

fn test_dir_in_with_no_out() {
	res := os.execute('$go2v_exe $quoted_path_test_area')
	assert res.exit_code == 0
	paths := os.ls(path_test_area)!
	assert 'hello.v' in paths
	os.rm(os.join_path_single(path_test_area, 'hello.v'))!
}

fn test_dir_in_with_file_out() {
	res := os.execute('$go2v_exe $quoted_path_test_area -o $quoted_go_test_file')
	assert res.exit_code != 0
	paths := os.ls(path_test_area)!
	assert 'hello.v' !in paths
}

fn test_dir_in_with_dir_out() {
	res := os.execute('$go2v_exe $quoted_path_test_area -o $quoted_path_test_area')
	assert res.exit_code == 0
	paths := os.ls(path_test_area)!
	assert 'hello.v' in paths
	os.rm(os.join_path_single(path_test_area, 'hello.v'))!
}
