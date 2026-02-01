package main

import "fmt"

func main() {
	type T string
	x := []T{"b", "a", "b", "c"}
	fmt.Println("x =", x)

	y := make(map[T]struct{}, len(x))
	for _, v := range x {
		y[v] = struct{}{}
	}
	x2 := make([]T, 0, len(y))
	for _, v := range x {
		if _, ok := y[v]; ok {
			x2 = append(x2, v)
			delete(y, v)
		}
	}
	x = x2

	fmt.Println("x =", x)
}
