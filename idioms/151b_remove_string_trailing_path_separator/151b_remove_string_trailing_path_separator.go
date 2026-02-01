package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	p := somePath()
	fmt.Println(p)

	sep := fmt.Sprintf("%c", filepath.Separator)
	p = strings.TrimSuffix(p, sep)

	fmt.Println(p)
}

func somePath() string {
	dir, err := ioutil.TempDir("", "")
	if err != nil {
		panic(err)
	}
	p := fmt.Sprintf("%s%c%s%c", dir, os.PathSeparator, "foobar", os.PathSeparator)
	return p
}
