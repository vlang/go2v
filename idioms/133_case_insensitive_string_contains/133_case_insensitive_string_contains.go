package main

import (
	"fmt"
	"strings"
)

// Package _strings has no case-insensitive version of _Contains, so
// we have to make our own.
func containsCaseInsensitive(s, word string) bool {
	lowerS, lowerWord := strings.ToLower(s), strings.ToLower(word)
	ok := strings.Contains(lowerS, lowerWord)
	return ok
}

func main() {
	s := "Let's dance the macarena"

	word := "Dance"
	ok := containsCaseInsensitive(s, word)
	fmt.Println(ok)

	word = "dance"
	ok = containsCaseInsensitive(s, word)
	fmt.Println(ok)

	word = "Duck"
	ok = containsCaseInsensitive(s, word)
	fmt.Println(ok)
}
