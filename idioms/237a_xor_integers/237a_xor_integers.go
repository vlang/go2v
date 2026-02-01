package main

import (
	"fmt"
)

func main() {
	a, b := 230, 42
	c := a ^ b

	fmt.Printf("a is %12b\n", a)
	fmt.Printf("b is %12b\n", b)
	fmt.Printf("c is %12b\n", c)
	fmt.Println("c ==", c)
}
