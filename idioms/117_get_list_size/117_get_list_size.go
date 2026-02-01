package main

import "fmt"

func main() {
	// x is a slice
	x := []string{"a", "b", "c"}
	n := len(x)
	fmt.Println(n)

	// y is an array
	y := [4]string{"a", "b", "c"}
	n = len(y)
	fmt.Println(n)
}
