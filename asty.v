import os

const gopath_res = os.execute('go env GOPATH')
const gopath_bin = os.join_path(gopath_res.output.trim_space(), '/bin')
const asty_executable_name = if os.user_os() == 'windows' { 'asty.exe' } else { 'asty' }
const full_path_to_asty = os.join_path(gopath_bin, asty_executable_name)

fn ensure_asty_is_installed() ! {
	if _ := os.find_abs_path_of_executable(asty_executable_name) {
		return
	}
	// Ensure that $GOPATH/bin is in PATH, and that asty is present, so invokin `asty` works:	
	if gopath_res.exit_code != 0 {
		return error('Failed to find Go. Visit https://go.dev/dl/ to see instructions, on how to install it.')
	}
	os.setenv('GOBIN', gopath_bin, true)
	os.setenv('PATH', os.getenv('PATH') + os.path_delimiter + gopath_bin, true)
	if !os.exists(gopath_bin) {
		os.mkdir_all(gopath_bin)!
	}
	if _ := os.find_abs_path_of_executable(asty_executable_name) {
		return
	}
	// Check if asty is installed:
	if !os.exists(full_path_to_asty) {
		println('asty not found in ${full_path_to_asty}, installing...')
		if os.system('go install github.com/asty-org/asty@latest') != 0 {
			return error('Failed to install asty. Please run: `go install github.com/asty-org/asty@latest` manually, and then make sure, that ${gopath_bin} is in your \$PATH.')
		}
	}
	os.find_abs_path_of_executable(asty_executable_name) or {
		os.system('ls -la ${gopath_bin}')
		return error('asty is still not installed in ${gopath_bin} ... Please run `go install github.com/asty-org/asty@latest`.')
	}
}
