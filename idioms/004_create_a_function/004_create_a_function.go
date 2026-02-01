package main

import (
	"fmt"
)

func square(x int) int {
	return x * x
}

func main() {
	n := square(9)
	fmt.Println(n)
}
