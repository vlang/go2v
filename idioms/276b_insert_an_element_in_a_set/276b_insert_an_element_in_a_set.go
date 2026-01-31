package main

import "fmt"

type E string

func main() {
	// declare a Set (implemented as a map)
	x := make(map[E]bool)

	// add an element
	var e E = "foo"
	x[e] = true

	for t, _ := range x {
		fmt.Printf("x contains element %q \n", t)
	}
}
