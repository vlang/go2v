package main

import "fmt"

func main() {
	x := []string{
		"a",
		"",
		"foo",
		"bar",
		"foo",
	}
	fmt.Printf("Before:\t x is %q\n", x)

	for i, s := range x {
		if s == "foo" {
			x[i] = "bar"
		}
	}

	fmt.Printf("After:\t x is %q\n", x)
}
