package main

import "fmt"

func main() {
	fmt.Println("Hello World")
	ok := Test1{}
	ok.a.Test()
	println("okkk")
}

type Test1 struct {
	a Test2
}

type Test2 struct{}

func (t Test2) Test() {
	fmt.Println("Test")
}
