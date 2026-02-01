package main

import "fmt"

func main() {
	items := []string{
		"oranges",
		"apples",
		"bananas",
	}

	for i := len(items) - 1; i >= 0; i-- {
		x := items[i]
		fmt.Printf("Item %d = %v \n", i, x)
	}
}
