package main

import "fmt"

// NewSquareMatrix creates a N-by-N matrix
func NewSquareMatrix(N int) ([][]float64, error) {
	if N < 0 {
		return nil, fmt.Errorf("Invalid size %d: order cannot be negative", N)
	}
	matrix := make([][]float64, N)
	for i := range matrix {
		matrix[i] = make([]float64, N)
	}
	return matrix, nil
}

func main() {
	N1 := 3
	matrix1, err1 := NewSquareMatrix(N1)
	if err1 == nil {
		fmt.Println(matrix1)
	} else {
		fmt.Println(err1)
	}

	N2 := -2
	matrix2, err2 := NewSquareMatrix(N2)
	if err2 == nil {
		fmt.Println(matrix2)
	} else {
		fmt.Println(err2)
	}
}
