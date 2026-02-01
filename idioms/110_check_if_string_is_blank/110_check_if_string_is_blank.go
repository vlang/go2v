package main

import (
	"fmt"
	"strings"
)

func main() {
	for _, s := range []string{
		"",
		"a",
		" ",
		"\t \n",
		"_",
	} {
		blank := strings.TrimSpace(s) == ""

		if blank {
			fmt.Printf("%q is blank\n", s)
		} else {
			fmt.Printf("%q is not blank\n", s)
		}
	}
}
