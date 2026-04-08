package main

import (
	"fmt"
)

func main() {
	type T string

	a := []T{"The ", "quick "}
	b := []T{"brown ", "fox "}

	ab := make([]T, len(a)+len(b))
	copy(ab, a)
	copy(ab[len(a):], b)

	fmt.Printf("%q", ab)
}
