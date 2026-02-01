package main

import "fmt"

func main() {
	const m, n, p = 2, 2, 3
	var x [m][n][p]float64

	x[1][0][2] = 9

	// Value of x
	fmt.Println(x)

	// Type of x
	fmt.Printf("%T", x)
}
