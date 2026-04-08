package main

import (
	"fmt"
	"strings"
)

func main() {
	x := map[string]string{
		"key1": "a",
		"key2": "Othello",
		"key3": "",
		"key4": "nicolas",
		"key5": "Bart",
	}

	p := func(s string) bool {
		// Return true if s is Capitalized, i.e. if its first character is uppercase.
		if s == "" {
			return false
		}
		c := s[:1]
		return c == strings.ToUpper(c)
	}

	fmt.Printf("Before:\t x is %q\n\n", x)

	for k, v := range x {
		if !p(v) {
			delete(x, k)
		}
	}

	fmt.Printf("After:\t x is %q\n\n", x)
}
