package main

import "fmt"

func main() {
	control(greet)
}

func control(f func()) {
	fmt.Println("Before f")
	f()
	fmt.Println("After f")
}

func greet() {
	fmt.Println("Hello, developers")
}
