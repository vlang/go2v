package main

import (
	"fmt"
)

func main() {
	items1 := []string{"a", "b"}
	items2 := []string{"A", "B", "C"}

	for i := 0; i < len(items1) || i < len(items2); i++ {
		if i < len(items1) {
			fmt.Println(items1[i])
		}
		if i < len(items2) {
			fmt.Println(items2[i])
		}
	}
}
