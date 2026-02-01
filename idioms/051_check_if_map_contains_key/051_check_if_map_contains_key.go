package main

import (
	"fmt"
)

func main() {
	m := map[string]int{
		"uno":  1,
		"dos":  2,
		"tres": 3,
	}

	k := "cinco"
	_, ok := m[k]
	fmt.Printf("m contains key %q: %v\n", k, ok)

	k = "tres"
	_, ok = m[k]
	fmt.Printf("m contains key %q: %v\n", k, ok)
}
