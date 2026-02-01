package main

import (
	"fmt"
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
		b := true
		for _, c := range s {
			if c < '0' || c > '9' {
				b = false
				break
			}
		}
		fmt.Println(s, "=>", b)
	}
}