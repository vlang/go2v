package main

import (
	"fmt"
	"sort"
)

type entry struct {
	key   string
	value int
}
type entries []entry

func (list entries) Len() int           { return len(list) }
func (list entries) Less(i, j int) bool { return list[i].value < list[j].value }
func (list entries) Swap(i, j int)      { list[i], list[j] = list[j], list[i] }

func main() {
	mymap := map[string]int{
		"one":   1,
		"two":   2,
		"three": 3,
		"four":  4,
		"dos":   2,
		"deux":  2,
	}

	entries := make(entries, 0, len(mymap))
	for k, x := range mymap {
		entries = append(entries, entry{key: k, value: x})
	}
	sort.Sort(entries)

	for _, e := range entries {
		fmt.Println("Key =", e.key, ", Value =", e.value)
	}
}
