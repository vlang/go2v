package main

import (
	"fmt"
)

func main() {
	items := []T{"b", "a", "b", "a", "r"}
	fmt.Println(items)

	var x T = "b"
	items2 := make([]T, 0, len(items))
	for _, v := range items {
		if v != x {
			items2 = append(items2, v)
		}
	}

	fmt.Println(items2)
}

type T string
