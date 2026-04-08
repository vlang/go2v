package main

import "fmt"

func main() {

	s := make([]int, 2)
	
	s[0] = 0
	s[1] = 2
	
	fmt.Println(s)	
	// insert one at index one
	s = append(s, 0)
	copy(s[2:], s[1:])
	s[1] = 1
	
	fmt.Println(s)
}