package main

import "fmt"

type E string

func main() {
	// declare a Set (implemented as a map)
	x := map[E]bool{
		"a": true,
		"b": true,
		"c": true,
	}

	// remove an element
	var e E = "b"
	delete(x, e)

	for t, _ := range x {
		fmt.Printf("x contains the element %q \n", t)
	}
}
