package main

import (
	"fmt"
)

func main() {
	a := []string{"The ", "quick "}
	b := []string{"brown ", "fox "}

	ab := append(a, b...)

	fmt.Printf("%q", ab)
}
