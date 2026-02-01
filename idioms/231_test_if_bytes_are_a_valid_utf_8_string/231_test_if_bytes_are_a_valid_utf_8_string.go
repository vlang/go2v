package main

import (
	"fmt"
	"unicode/utf8"
)

func main() {
	{
		s := []byte("Hello, 世界")
		b := utf8.Valid(s)
		fmt.Println(b)
	}
	{
		s := []byte{0xff, 0xfe, 0xfd}
		b := utf8.Valid(s)
		fmt.Println(b)
	}
}
