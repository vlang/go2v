package main

import (
	"fmt"
	"strings"
)

func main() {
	p := "/usr/bin/"

	p = strings.TrimSuffix(p, "/")

	fmt.Println(p)
}
