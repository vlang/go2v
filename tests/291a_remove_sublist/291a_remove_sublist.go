package main

import "fmt"

type T *string

func main() {
	items := []T{
		newT("a"),
		newT("b"),
		newT("c"),
		newT("d"),
		newT("e"),
	}

	i, j := 2, 4

	copy(items[i:], items[j:])
	for k, n := len(items)-j+i, len(items); k < n; k++ {
		items[k] = nil
	}
	items = items[:len(items)-j+i]

	for _, item := range items {
		fmt.Println(*item)
	}
}

func newT(s string) T {
	return &s
}
