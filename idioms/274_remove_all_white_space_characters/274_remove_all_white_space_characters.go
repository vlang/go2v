package main

import (
	"fmt"
	"strings"
	"unicode"
)

const s = `
 a   string full	of
white	space
 `

func main() {

	t := strings.Map(func(r rune) rune {
		if unicode.IsSpace(r) {
			// if the character is a space, drop it
			return -1
		}
		// else keep it in the string
		return r
	}, s)

	fmt.Printf("t=%q", t)
}
