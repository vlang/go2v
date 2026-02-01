package main

import (
	"fmt"
	"math/rand"
)

func main() {
	x := []string{"a", "b", "c", "d", "e", "f", "g", "h"}

	rand.Shuffle(len(x), func(i, j int) {
		x[i], x[j] = x[j], x[i]
	})

	fmt.Println(x)
}
