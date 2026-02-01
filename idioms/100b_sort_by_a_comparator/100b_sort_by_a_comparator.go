package main

import "fmt"
import "sort"

type Item struct {
	label string
	p     int
	lang  string
}

type ItemsSorter struct {
	items []Item
	c     func(x, y Item) bool
}

func (s ItemsSorter) Len() int           { return len(s.items) }
func (s ItemsSorter) Less(i, j int) bool { return s.c(s.items[i], s.items[j]) }
func (s ItemsSorter) Swap(i, j int)      { s.items[i], s.items[j] = s.items[j], s.items[i] }

func sortItems(items []Item, c func(x, y Item) bool) {
	sorter := ItemsSorter{
		items,
		c,
	}
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

	c := func(x, y Item) bool {
		return x.p < y.p
	}
	sortItems(items, c)

	fmt.Println("Sorted: ", items)
}
