package main

import (
	"fmt"
	"regexp"
)

// regexp created only once, and then reused
var whitespaces = regexp.MustCompile(`\s+`)

func main() {
	s := `
	one   two
	   three
	`

	t := whitespaces.ReplaceAllString(s, " ")

	fmt.Printf("t=%q", t)
}
