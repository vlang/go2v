package main

import "fmt"

func fn() {
	match()
}
func match() {
	fmt.Println("hey")
}

type Foo struct {
	match bool
}

func main() {
	fn()
}
