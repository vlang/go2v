package main

import (
	"fmt"
)

func f() {
	fmt.Println("Larger found")
}

func main() {
	a := []int{1, 2, 3, 4, 5}
	x := 4
	for _, v := range a {
		if v > x {
			f()
			break
		}
	}
}