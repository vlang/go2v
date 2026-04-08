package main

import (
	"fmt"
	"strings"
	"unicode"
)

func main() {
	s := "5#∑∂ƒ∞645eyfu"
	t := strings.Map(func(r rune) rune {
		if r > unicode.MaxASCII {
			return -1
		}
		return r
	}, s)
	fmt.Println(t)
}
