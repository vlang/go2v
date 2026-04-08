package main

import (
	"fmt"
	"strings"
)

func check(s, prefix string) {

	b := strings.HasPrefix(s, prefix)

	if b {
		fmt.Println(s, "starts with", prefix)
	} else {
		fmt.Println(s, "doesn't start with", prefix)
	}
}

func main() {
	check("bar", "foo")
	check("foobar", "foo")
}
