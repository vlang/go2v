package main

import (
	"fmt"
)

func main() {
	// a, b and c don't need to have the same type.

	a, b, c := 42, "hello", 5.0

	fmt.Println(a, b, c)
	fmt.Printf("%T %T %T \n", a, b, c)
}
