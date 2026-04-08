package main

import (
	"fmt"
	"math/rand"
)

func main() {
	x := pick(-2.0, 6.5)
	fmt.Println(x)
}

func pick(a, b float64) float64 {
	return a + (rand.Float64() * (b - a))
}
