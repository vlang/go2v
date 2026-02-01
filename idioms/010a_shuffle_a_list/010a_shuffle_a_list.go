package main

import (
	"fmt"
	"math/rand"
)

func main() {
	x := []string{"a", "b", "c", "d", "e", "f", "g", "h"}

	for i := range x {
		j := rand.Intn(i + 1)
		x[i], x[j] = x[j], x[i]
	}

	fmt.Println(x)
}
