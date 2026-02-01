package main

import (
	"math"
)

func main() {
	data := []float64{0.06, 0.82, -0.01, -0.34, -0.55}
	var s float64
	for _, d := range data {
		s += math.Pow(d, 2)
	}
	println(s)
}
