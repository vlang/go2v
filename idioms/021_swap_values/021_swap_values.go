package main

import "fmt"

func main() {
	a := 3
	b := 10
	a, b = b, a
	fmt.Println(a)
	fmt.Println(b)
}
