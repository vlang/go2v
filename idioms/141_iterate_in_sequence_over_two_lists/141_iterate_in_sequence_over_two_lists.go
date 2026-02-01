package main

import (
	"fmt"
)

func main() {
	items1 := []string{"a", "b", "c"}
	items2 := []string{"A", "B", "C"}

	for _, v := range items1 {
		fmt.Println(v)
	}
	for _, v := range items2 {
		fmt.Println(v)
	}
}
