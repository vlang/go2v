package main

import (
	"fmt"
)

func P(e int) bool {
	// Predicate "is even"
	return e%2 == 0
}

type Result = int

func T(e int) Result {
	// Transformation "square"
	return e * e
}

func main() {
	x := []int{4, 5, 6, 7, 8, 9, 10}

	var y []Result
	for _, e := range x {
		if P(e) {
			y = append(y, T(e))
		}
	}

	fmt.Println(y)
}