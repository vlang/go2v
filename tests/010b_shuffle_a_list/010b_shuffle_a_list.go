package main

import (
	"fmt"
	"math/rand"
)

func main() {
	x := []string{"a", "b", "c", "d", "e", "f", "g", "h"}

	y := make([]string, len(x))
	perm := rand.Perm(len(x))
	for i, v := range perm {
		y[v] = x[i]
	}

	fmt.Println(y)
}
