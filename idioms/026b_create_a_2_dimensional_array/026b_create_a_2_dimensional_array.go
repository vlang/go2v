package main

import "fmt"

func main() {
	x := make2D(2, 3)

	x[1][1] = 8
	fmt.Println(x)
}

func make2D(m, n int) [][]float64 {
	buf := make([]float64, m*n)

	x := make([][]float64, m)
	for i := range x {
		x[i] = buf[:n:n]
		buf = buf[n:]
	}
	return x
}