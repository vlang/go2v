package main

import (
	"fmt"
	"sort"
)

func main() {
	mymap := map[string]int{
		"one":   1,
		"two":   2,
		"three": 3,
		"four":  4,
		"dos":   2,
		"deux":  2,
	}

	type entry struct {
		key   string
		value int
	}

	entries := make([]entry, 0, len(mymap))
	for k, x := range mymap {
		entries = append(entries, entry{key: k, value: x})
	}
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].value < entries[j].value
	})

	for _, e := range entries {
		fmt.Println("Key =", e.key, ", Value =", e.value)
	}
}
