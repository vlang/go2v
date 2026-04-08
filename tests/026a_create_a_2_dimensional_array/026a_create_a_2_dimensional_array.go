package main

import "fmt"

func main() {
	const m, n = 3, 4
	var x [m][n]float64

	x[1][2] = 8
	fmt.Println(x)
}
