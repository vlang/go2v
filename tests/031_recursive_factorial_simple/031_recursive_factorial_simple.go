package main

import (
	"fmt"
)

func f(i int) int {
	if i == 0 {
		return 1
	}
	return i * f(i-1)
}

func main() {
	for i := 0; i <= 10; i++ {
		fmt.Printf("f(%d) = %d\n", i, f(i))
	}
}