package main

import "fmt"

type T string

func main() {
	// declare a Set (implemented as a map)
	x := make(map[T]struct{})

	// add some elements
	x["A"] = struct{}{}
	x["B"] = struct{}{}
	x["B"] = struct{}{}
	x["C"] = struct{}{}
	x["D"] = struct{}{}

	// remove an element
	delete(x, "C")

	for t, _ := range x {
		fmt.Printf("x contains element %v \n", t)
	}
}
