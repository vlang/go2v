package main

import (
	"fmt"
)

func containsValue(m map[K]T, v T) bool {
	for _, x := range m {
		if x == v {
			return true
		}
	}
	return false
}

// Arbitrary types for K, T.
type K string
type T int

func main() {
	m := map[K]T{
		"uno":  1,
		"dos":  2,
		"tres": 3,
	}

	var v T = 5
	ok := containsValue(m, v)
	fmt.Printf("m contains value %d: %v\n", v, ok)

	v = 3
	ok = containsValue(m, v)
	fmt.Printf("m contains value %d: %v\n", v, ok)
}
