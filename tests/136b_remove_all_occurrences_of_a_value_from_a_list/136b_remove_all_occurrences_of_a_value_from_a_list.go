package main

import (
	"fmt"
)

func main() {
	items := []T{"b", "a", "b", "a", "r"}
	fmt.Println(items)

	x := T("b")
	j := 0
	for i, v := range items {
		if v != x {
			items[j] = items[i]
			j++
		}
	}
	items = items[:j]

	fmt.Println(items)
}

type T string