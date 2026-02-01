package main

import (
	"fmt"
	"math"
)

func round(x float64) int {
	y := int(math.Floor(x + 0.5))
	return y
}

func main() {
	for _, x := range []float64{-1.1, -0.9, -0.5, -0.1, 0., 0.1, 0.5, 0.9, 1.1} {
		fmt.Printf("%5.1f %5d\n", x, round(x))
	}
}
