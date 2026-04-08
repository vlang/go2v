package main

import "fmt"

type E string

func main() {
	// declare a Set (implemented as a map)
	x := make(map[E]bool)

	// add an element
	x["foo"] = true

	{
		var e E = "foo"
		b := x[e]
		fmt.Printf("x contains %q: %t\n", e, b)
	}
	{
		var e E = "barbaz"
		b := x[e]
		fmt.Printf("x contains %q: %t\n", e, b)
	}
}
