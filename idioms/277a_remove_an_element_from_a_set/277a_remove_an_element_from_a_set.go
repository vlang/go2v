package main

import "fmt"

type E string

func main() {
	// declare and initialize a Set (implemented as a map)
	x := map[E]struct{}{
		"a": struct{}{},
		"b": struct{}{},
		"c": struct{}{},
	}

	// remove an element
	var e E = "b"
	delete(x, e)

	for t, _ := range x {
		fmt.Printf("x contains the element %q \n", t)
	}
}