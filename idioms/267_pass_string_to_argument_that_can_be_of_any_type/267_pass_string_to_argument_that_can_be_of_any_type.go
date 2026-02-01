package main

import (
	"fmt"
)

func foo(x interface{}) {
	if s, ok := x.(string); ok {
		fmt.Println(s)
	} else {
		fmt.Println("Nothing.")
	}
}

func main() {
	foo("Hello, world!")
	foo(42)
}
