package main

import (
	"fmt"
	"sort"
)

func binarySearch(a []int, x int) int {
	i := sort.SearchInts(a, x)
	if i < len(a) && a[i] == x {
		return i
	}
	return -1
}

func main() {
	a := []int{-2, -1, 0, 1, 1, 1, 6, 8, 8, 9, 10}
	for x := -5; x <= 15; x++ {
		i := binarySearch(a, x)
		if i == -1 {
			fmt.Println("Value", x, "not found")
		} else {
			fmt.Println("Value", x, "found at index", i)
		}
	}
}
