package main

import "fmt"

func main() {
	items := []string{
		"oranges",
		"apples",
		"bananas",
	}

	for i, x := range items {
		fmt.Printf("Item %d = %v \n", i, x)
	}
}
