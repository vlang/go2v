package main

import "fmt"

func printSubtraction(a []int, b []int) {
mainloop:
	for _, v := range a {
		for _, w := range b {
			if v == w {
				continue mainloop
			}
		}
		fmt.Println(v)
	}
}

func main() {
	a := []int{1, 2, 3, 4}
	b := []int{2, 4, 6, 8}
	printSubtraction(a, b)
}
