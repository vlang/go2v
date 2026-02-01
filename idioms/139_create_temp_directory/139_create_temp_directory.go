package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
)

func main() {
	content := []byte("temporary file's content")
	dir, err := ioutil.TempDir("", "")
	if err != nil {
		log.Fatal(err)
	}

	defer os.RemoveAll(dir) // clean up

	inspect(dir)

	tmpfn := filepath.Join(dir, "tmpfile")
	err = ioutil.WriteFile(tmpfn, content, 0666)
	if err != nil {
		log.Fatal(err)
	}

	inspect(dir)
}

func inspect(dirpath string) {
	files, err := ioutil.ReadDir(dirpath)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(dirpath, "contains", len(files), "files")
}
