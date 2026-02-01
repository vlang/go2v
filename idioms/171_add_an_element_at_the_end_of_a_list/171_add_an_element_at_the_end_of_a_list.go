package main

import "fmt"

func main() {
	s := []int{1, 1, 2, 3, 5, 8, 13}
	x := 21

	s = append(s, x)

	fmt.Println(s)
}
