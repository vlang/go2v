package main

import "fmt"

func Contains(list []T, x T) bool {
	for _, item := range list {
		if item == x {
			return true
		}
	}
	return false
}

type T string

func main() {
	list := []T{"a", "b", "c"}
	fmt.Println(Contains(list, "b"))
	fmt.Println(Contains(list, "z"))
}