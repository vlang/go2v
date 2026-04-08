package main

import (
	"fmt"
)

const n = 1024

func main() {
	x := make([]bool, n)

	x[42] = true

	for _, y := range []int{13, 42} {
		fmt.Println("x has bit", y, "set to", x[y])
	}
}