package main

import (
	"fmt"
)

type T int

func main() {
	a := []T{4, 5, 6, 7, 8, 9, 10}
	b := []T{1, 3, 9, 5, 7, 9, 7, 7}

	// Convert to sets
	seta := make(map[T]bool, len(a))
	for _, x := range a {
		seta[x] = true
	}
	setb := make(map[T]bool, len(a))
	for _, y := range b {
		setb[y] = true
	}

	// Iterate in one pass
	var c []T
	for x := range seta {
		if setb[x] {
			c = append(c, x)
		}
	}

	fmt.Println(c)
}