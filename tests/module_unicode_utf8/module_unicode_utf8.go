package main

import (
	"fmt"
	"unicode/utf8"
)

func main() {
	// EncodeRune
	b := []byte("Hello, 世界")
	x := 'a'
	a := 1 + utf8.EncodeRune(b, x)
	fmt.Println(b)
	fmt.Println(a)

	// RuneLen
	fmt.Println(utf8.RuneLen('世'))

	// RuneStart
	buf := []byte("a界")
	fmt.Println(utf8.RuneStart(buf[0]))
	fmt.Println(utf8.RuneStart(buf[1]))
	fmt.Println(utf8.RuneStart(buf[2]))

	// Valid
	valid := []byte("Hello, 世界")
	invalid := []byte{0xff, 0xfe, 0xfd}

	fmt.Println(utf8.Valid(valid))
	fmt.Println(utf8.Valid(invalid))
}
