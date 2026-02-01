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
	}

	keys := make([]string, 0, len(mymap))
	for k := range mymap {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	for _, k := range keys {
		x := mymap[k]
		fmt.Println("Key =", k, ", Value =", x)
	}
}
