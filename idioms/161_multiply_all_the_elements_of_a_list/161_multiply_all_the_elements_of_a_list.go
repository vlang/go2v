package main

import (
	"fmt"
)

func main() {
	const c = 5.5
	elements := []float64{2, 4, 9, 30}
	fmt.Println(elements)

	for i := range elements {
		elements[i] *= c
	}
	fmt.Println(elements)
}
