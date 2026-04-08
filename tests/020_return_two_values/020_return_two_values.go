package main

import "fmt"

func main() {
	matrix := [][]int{
		{1, 2, 3},
		{4, 5, 6},
		{7, 8, 9},
	}
	for x := 1; x <= 11; x += 2 {
		found, i, j := search(matrix, x)
		if found {
			fmt.Printf("matrix[%v][%v] == %v \n", i, j, x)
		} else {
			fmt.Printf("Value %v not found. \n", x)
		}
	}
}
