package main

import (
	"fmt"
)

func main() {
	type T string
	items := []T{"a", "b", "b", "aaa", "c", "a", "d"}
	fmt.Println("items has", len(items), "elements")

	distinct := make(map[T]bool)
	for _, v := range items {
		distinct[v] = true
	}
	c := len(distinct)

	fmt.Println("items has", c, "distinct elements")
}
