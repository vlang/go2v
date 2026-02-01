package main

import (
	"fmt"
)

func main() {
	items := []string{"huey", "dewey", "louie"}
	x := "dewey"

	i := -1
	for j, e := range items {
		if e == x {
			i = j
			break
		}
	}

	fmt.Printf("Found %q at position %d in %q", x, i, items)
}
