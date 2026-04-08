package main

import "fmt"

func main() {
	x := []int{1, 2, 3}
	s := 0
	for _, v := range x {
		s += v
	}
	fmt.Println(s)
}