package main

import "fmt"

func main() {
	x := make3D(2, 2, 3)

	x[1][0][2] = 9
	fmt.Println(x)
}

func make3D(m, n, p int) [][][]float64 {
	buf := make([]float64, m*n*p)

	x := make([][][]float64, m)
	for i := range x {
		x[i] = make([][]float64, n)
		for j := range x[i] {
			x[i][j] = buf[:p:p]
			buf = buf[p:]
		}
	}
	return x
}
