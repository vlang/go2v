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

type ItemCSorter []Item

func (s ItemCSorter) Len() int           { return len(s) }
func (s ItemCSorter) Less(i, j int) bool { return c(s[i], s[j]) }
func (s ItemCSorter) Swap(i, j int)      { s[i], s[j] = s[j], s[i] }

func sortItems(items []Item) {
	sorter := ItemCSorter(items)
	sort.Sort(sorter)
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
	sortItems(items)
	fmt.Println("Sorted: ", items)
}
