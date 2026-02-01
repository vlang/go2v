package main

import (
	"fmt"
	"strings"
)

func main() {
	v := "abc"
	n := 5

	s := strings.Repeat(v, n)

	fmt.Println(s)
}
