package main

import "fmt"

type Parent struct {
	name string
}

// A Factory is a function which returns an object
type ParentFactory func(string) Parent

func main() {
	var fact ParentFactory = func(str string) Parent {
		return Parent{
			name: str,
		}
	}

	var p Parent = fact("Daddy")
	fmt.Println(p)
}
