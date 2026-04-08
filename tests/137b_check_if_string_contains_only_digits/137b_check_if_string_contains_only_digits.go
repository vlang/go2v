package main

import (
	"fmt"
	"strings"
)

func main() {
	for _, s := range []string{
		"123",
		"",
		"abc123def",
		"abc",
		"123.456",
		"123 456",
	} {
		isNotDigit := func(c rune) bool { return c < '0' || c > '9' }
		b := strings.IndexFunc(s, isNotDigit) == -1
		fmt.Println(s, "=>", b)
	}
}