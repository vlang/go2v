package main

import (
	"fmt"
	"math"
)

func applyFormula(a, b, c, d []float64, e float64) {
	for i, v := range a {
		a[i] = e * (v + b[i] + c[i] + math.Cos(d[i]))
	}
}

func main() {
	a := []float64{1, 2, 3, 4}
	b := []float64{5.5, 6.6, 7.7, 8.8}
	c := []float64{9, 10, 11, 12}
	d := []float64{13, 14, 15, 16}
	e := 42.0

	fmt.Println("a is    ", a)
	applyFormula(a, b, c, d, e)
	fmt.Println("a is now", a)
}
