package main

import (
	"fmt"
	"strings"
	"unicode/utf8"
)

func main() {
	m := 3
	c := "-"
	for _, s := range []string{
		"",
		"a",
		"ab",
		"abc",
		"abcd",
		"é",
	} {
		if n := utf8.RuneCountInString(s); n < m {
			s = strings.Repeat(c, m-n) + s
		}
		fmt.Println(s)
	}
}
