package main

import "fmt"
import "sort"

type Item struct {
	label string
	p     int
	lang  string
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

	less := func(i, j int) bool {
		return items[i].p < items[j].p
	}
	sort.Slice(items, less)

	fmt.Println("Sorted: ", items)
}
