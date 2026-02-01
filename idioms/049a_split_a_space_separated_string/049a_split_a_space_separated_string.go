package main

import (
	"fmt"
	"strings"
)

func main() {
	s := "Un dos tres"
	chunks := strings.Split(s, " ")
	fmt.Println(len(chunks))
	fmt.Println(chunks)

	s = " Un dos tres "
	chunks = strings.Split(s, " ")
	fmt.Println(len(chunks))
	fmt.Println(chunks)

	s = "Un  dos"
	chunks = strings.Split(s, " ")
	fmt.Println(len(chunks))
	fmt.Println(chunks)
}