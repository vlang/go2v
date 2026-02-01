package main

import (
	"fmt"
)

func main() {
	x, y, z := f()

	fmt.Println(x, y, z)
}

func f() (float64, string, chan int) {
	a, b, c := 2.5, "hello", make(chan int)
	return a, b, c
}
