package main

import "fmt"

type T int

func main() {
	x := []T{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
	p := func(t T) bool { return t%2 == 0 }

	n := 0
	for _, v := range x {
		if p(v) {
			n++
		}
	}
	y := make([]T, 0, n)
	for _, v := range x {
		if p(v) {
			y = append(y, v)
		}
	}

	fmt.Println(y)
}
