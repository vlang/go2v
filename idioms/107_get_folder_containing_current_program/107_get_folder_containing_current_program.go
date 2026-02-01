package main

import (
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	var dir string

	programPath := os.Args[0]
	absolutePath, err := filepath.Abs(programPath)
	if err != nil {
		panic(err)
	}
	dir = filepath.Dir(absolutePath)

	fmt.Println(dir)
}
