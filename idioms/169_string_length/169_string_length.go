package main

import "fmt"
import "unicode/utf8"

func main() {
	s := "Hello, 世界"
	n := utf8.RuneCountInString(s)

	fmt.Println(n)
}
