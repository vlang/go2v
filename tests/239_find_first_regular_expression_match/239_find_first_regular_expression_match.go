package main

import (
	"fmt"
	"regexp"
)

func main() {
	re := regexp.MustCompile(`\b\d\d\d\b`)
	for _, s := range []string{
		"",
		"12",
		"123",
		"1234",
		"I have 12 goats, 3988 otters, 224 shrimps and 456 giraffes",
		"See p.456, for word boundaries",
	} {
		x := re.FindString(s)
		fmt.Printf("%q -> %q\n", s, x)
	}
}
