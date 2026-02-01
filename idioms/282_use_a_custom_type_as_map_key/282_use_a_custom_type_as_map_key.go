package main

import "fmt"

func main() {
	type Foo struct {
		name string
		x, y int
	}

	m := make(map[Foo]string)
	foo := Foo{name: "John", x: 42, y: 5}
	m[foo] = "Professor"

	fmt.Println(m)
}
