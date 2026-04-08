package main

import (
	"fmt"
	"strings"
)

func check(s, suffix string) {

	b := strings.HasSuffix(s, suffix)

	if b {
		fmt.Println(s, "ends with", suffix)
	} else {
		fmt.Println(s, "doesn't end with", suffix)
	}
}

func main() {
	check("foo", "bar")
	check("foobar", "bar")
}