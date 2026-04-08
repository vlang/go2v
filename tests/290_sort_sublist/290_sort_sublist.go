package main

import (
	"fmt"
	"sort"
)

type Item struct {
	label string
}

// c returns true if x is "inferior to" y (in a custom way)
func c(x, y Item) bool {
	return x.label < y.label
}

func main() {
	items := []Item{
		{"start"},
		{"ccc"},
		{"aaa"},
		{"ddd"},
		{"bbb"},
		{"end"},
	}
	fmt.Println("Unsorted:", items)

	// Sort the slice, except the first and the last elements
	i, j := 1, len(items)-1
	sub := items[i:j]
	sort.Slice(sub, func(a, b int) bool {
		return c(sub[a], sub[b])
	})
	fmt.Println("Sorted:  ", items)
}
