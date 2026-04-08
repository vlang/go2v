package main

import (
	"fmt"
)

func main() {
	s, b := foo()
	fmt.Println(s, b)
}

func foo() (string, bool) {
	return "Too good to be", true
}
