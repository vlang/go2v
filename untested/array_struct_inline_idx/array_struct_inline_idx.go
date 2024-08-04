package main

import "fmt"

type Node struct {
	Abc bool
}

func main() {
	a := [...]Node{
		0: {
			Abc: true,
		},
		1: {
			Abc: true,
		},
	}
	fmt.Println(a)
}
