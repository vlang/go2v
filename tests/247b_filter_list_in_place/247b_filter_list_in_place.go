package main

import "fmt"

type T int

func main() {
	var x []*T
	for _, v := range []T{1, 2, 3, 4, 5, 6, 7, 8, 9, 10} {
		t := new(T)
		*t = v
		x = append(x, t)
	}
	p := func(t *T) bool { return *t%2 == 0 }

	j := 0
	for i, v := range x {
		if p(v) {
			x[j] = x[i]
			j++
		}
	}
	for k := j; k < len(x); k++ {
		x[k] = nil
	}
	x = x[:j]

	for _, pt := range x {
		fmt.Print(*pt, " ")
	}
}
