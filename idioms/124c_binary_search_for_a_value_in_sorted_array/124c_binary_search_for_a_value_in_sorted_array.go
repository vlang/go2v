package main

import (
	"fmt"
	"sort"
)

func binarySearch(a []T, x T) int {
	f := func(i int) bool { return a[i] >= x }
	i := sort.Search(len(a), f)
	if i < len(a) && a[i] == x {
		return i
	}
	return -1
}

type T int

func main() {
	a := []T{-2, -1, 0, 1, 1, 1, 6, 8, 8, 9, 10}
	for x := T(-5); x <= 15; x++ {
		i := binarySearch(a, x)
		if i == -1 {
			fmt.Println("Value", x, "not found")
		} else {
			fmt.Println("Value", x, "found at index", i)
		}
	}
}
