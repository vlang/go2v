package main

import (
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	var s string

	path := os.Args[0]
	s = filepath.Base(path)

	fmt.Println(s)
}
