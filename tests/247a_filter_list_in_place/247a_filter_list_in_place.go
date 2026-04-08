package main

import "fmt"

type T int

func main() {
	x := []T{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
	p := func(t T) bool { return t%2 == 0 }

	j := 0
	for i, v := range x {
		if p(v) {
			x[j] = x[i]
			j++
		}
	}
	x = x[:j]

	fmt.Println(x)
}
