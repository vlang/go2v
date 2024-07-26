import os

if os.args.len != 2 {
	println('Usage: v run ast2json.vsh file.go')
	return
}

file := os.args[1]

// Check if asty is installed
asty_installed := os.system('go list -m -json github.com/asty-org/asty > /dev/null 2>&1') == 0

if !asty_installed {
	println('asty not found, installing...')
	install_result := os.system('go install github.com/asty-org/asty@latest')
	if install_result != 0 {
		eprintln('Failed to install asty')
		return
	}
}

// Run asty go2json
output_file := '${file}.json'
cmd := 'asty go2json -indent 2 -input $file -output $output_file'
run_result := os.system(cmd)

if run_result != 0 {
	eprintln('Failed to run asty')
	return


}


    // Replace "NodeType": " with "_type": "
    json_content := os.read_file(output_file) or {
        eprintln('Failed to read $output_file')
        return
    }

    updated_content := json_content.replace('"NodeType": "', '"_type": "')

    os.write_file(output_file, updated_content) or {
        eprintln('Failed to write to $output_file')
        return
    }
println('Successfully converted $file to $output_file')

