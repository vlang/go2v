package main

import (
	"fmt"
	"strings"
)

func main() {
	s := "Un dos tres"
	chunks := strings.Fields(s)
	fmt.Println(len(chunks))
	fmt.Println(chunks)

	s = " Un dos tres "
	chunks = strings.Fields(s)
	fmt.Println(len(chunks))
	fmt.Println(chunks)

	s = "Un  dos"
	chunks = strings.Fields(s)
	fmt.Println(len(chunks))
	fmt.Println(chunks)
}
