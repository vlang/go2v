package main

import "fmt"

func main() {
	x := []string{"b", "a", "b", "c"}
	fmt.Println("x =", x)

	y := make(map[string]struct{}, len(x))
	for _, v := range x {
		y[v] = struct{}{}
	}

	fmt.Println("y =", y)
}
