package main

import (
	"fmt"
	"strings"
)

func main() {
	s := "Love is all is alright"
	sep := " is "

	parts := strings.Split(s, sep)

	fmt.Println(len(parts))
	fmt.Println(parts)
}
