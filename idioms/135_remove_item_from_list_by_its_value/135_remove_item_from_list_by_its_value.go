package main

import (
	"fmt"
)

func main() {
	items := []string{"a", "b", "c", "d", "e", "f"}
	fmt.Println(items)

	x := "c"
	for i, y := range items {
		if y == x {
			items = append(items[:i], items[i+1:]...)
			break
		}
	}
	fmt.Println(items)
}