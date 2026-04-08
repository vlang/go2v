package main

import "fmt"

func main() {
	a, b := "Hello", " Universe"

	s := a + b

	fmt.Printf("a is %q\n", a)
	fmt.Printf("b is %q\n", b)
	fmt.Printf("s is %q\n", s)
}
