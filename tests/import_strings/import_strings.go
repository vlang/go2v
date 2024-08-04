package main

import (
	"fmt"
	"os"
	"path"
	"strings"
)

func main() {
	progname := path.Base(os.Args[0])
	fmt.Println(progname)
	p := strings.SplitN(progname, "-", 2)
	fmt.Println(p)
	fmt.Println("Hello")
}
