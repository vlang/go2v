package main

import "fmt"

type T string

func main() {
	// declare a Set (implemented as a map)
	x := make(map[T]bool)

	// add some elements
	x["A"] = true
	x["B"] = true
	x["B"] = true
	x["C"] = true
	x["D"] = true

	// remove an element
	delete(x, "C")

	for e := range x {
		f(e)
	}
}

func f(e T) {
	fmt.Printf("contains element %v \n", e)
}
