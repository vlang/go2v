package main

import "fmt"

func main() {
	type T string
	x := []T{"b", "a", "b", "b", "c", "b", "a"}
	fmt.Println("x =", x)

	seen := make(map[T]bool)
	j := 0
	for _, v := range x {
		if !seen[v] {
			x[j] = v
			j++
			seen[v] = true
		}
	}
	x = x[:j]

	fmt.Println("x =", x)
}
