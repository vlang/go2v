package main

import "fmt"
import "sort"

type Item struct {
	label string
	p     int
	lang  string
}

type ItemPSorter []Item

func (s ItemPSorter) Len() int           { return len(s) }
func (s ItemPSorter) Less(i, j int) bool { return s[i].p < s[j].p }
func (s ItemPSorter) Swap(i, j int)      { s[i], s[j] = s[j], s[i] }

func sortItems(items []Item) {
	sorter := ItemPSorter(items)
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
