package main

import (
	"fmt"
)

func main() {
	items := []string{"a", "b", "c", "d", "e", "f"}
	fmt.Println(items)

	i := 2
	items = append(items[:i], items[i+1:]...)
	fmt.Println(items)
}