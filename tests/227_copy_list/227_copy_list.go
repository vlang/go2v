package main

import (
	"fmt"
)

func main() {
	type T string
	x := []T{"Never", "gonna", "shower"}

	y := make([]T, len(x))
	copy(y, x)

	y[2] = "give"
	y = append(y, "you", "up")

	fmt.Println(x)
	fmt.Println(y)
}
