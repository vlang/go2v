package main

import "fmt"
import "sort"

type Item struct {
	label string
	p     int
	lang  string
}

// c returns true if x is "inferior to" y (in a custom way)
func c(x, y Item) bool {
	return x.p < y.p
}

func main() {
	items := []Item{
		{"twelve", 12, "english"},
		{"six", 6, "english"},
		{"eleven", 11, "english"},
		{"zero", 0, "english"},
		{"two", 2, "english"},
	}
	fmt.Println("Unsorted: ", items)
	
	sort.Slice(items, func(i, j int) bool {
		return c(items[i], items[j])
	})
	
	fmt.Println("Sorted: ", items)
}
