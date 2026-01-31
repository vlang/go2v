package main

import "fmt"

type T string

func main() {
	items := []T{"a", "b", "c", "d", "e"}

	i, j := 2, 4

	items = append(items[:i], items[j:]...)

	fmt.Printf("%q", items)
}
