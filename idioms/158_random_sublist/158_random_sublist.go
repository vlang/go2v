package main

import (
	"fmt"
	"math/rand"
)

func main() {
	type T string

	x := []T{"Alice", "Bob", "Carol", "Dan", "Eve", "Frank", "Grace", "Heidi"}
	k := 4

	y := make([]T, k)
	perm := rand.Perm(len(x))
	for i, v := range perm[:k] {
		y[i] = x[v]
	}

	fmt.Printf("%q", y)
}
