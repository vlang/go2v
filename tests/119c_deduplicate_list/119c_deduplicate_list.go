package main

import "fmt"

type T *int64

func main() {
	var a, b, c, d int64 = 11, 22, 33, 11
	x := []T{&b, &a, &b, &b, &c, &b, &a, &d}
	print(x)

	seen := make(map[T]bool)
	j := 0
	for _, v := range x {
		if !seen[v] {
			x[j] = v
			j++
			seen[v] = true
		}
	}
	for i := j; i < len(x); i++ {
		// Avoid memory leak
		x[i] = nil
	}
	x = x[:j]

	// Now x has only distinct pointers (even if some point to int64 values that are the same)
	print(x)
}

func print(a []T) {
	glue := ""
	for _, p := range a {
		fmt.Printf("%s%d", glue, *p)
		glue = ", "
	}
	fmt.Println()
}
