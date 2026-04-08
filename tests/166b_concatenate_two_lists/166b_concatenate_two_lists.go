package main

import (
	"fmt"
)

func main() {
	type T string

	a := []T{"The ", "quick "}
	b := []T{"brown ", "fox "}

	var ab []T
	ab = append(append(ab, a...), b...)

	fmt.Printf("%q", ab)
}
