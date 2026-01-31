package main

import "fmt"

type E string

func main() {
	// declare a Set (implemented as a map)
	x := make(map[E]struct{})

	// add an element
	x["foo"] = struct{}{}

	{
		var e E = "foo"
		_, b := x[e]
		fmt.Printf("x contains %q: %t\n", e, b)
	}
	{
		var e E = "barbaz"
		_, b := x[e]
		fmt.Printf("x contains %q: %t\n", e, b)
	}
}
