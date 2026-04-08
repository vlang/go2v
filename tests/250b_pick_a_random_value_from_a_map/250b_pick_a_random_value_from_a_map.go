package main

import (
	"fmt"
	"math/rand"
)

type K string
type V string

func pick(m map[K]V) V {
	k := rand.Intn(len(m))
	for _, x := range m {
		if k == 0 {
			return x
		}
		k--
	}
	panic("unreachable")
}

func main() {
	m := map[K]V{
		"one":   "un",
		"two":   "deux",
		"three": "trois",
		"four":  "quatre",
	}

	x := pick(m)

	fmt.Println(x)
}
