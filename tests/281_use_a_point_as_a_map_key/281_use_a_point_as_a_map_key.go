package main

import "fmt"

type Point struct {
	x, y int
}

func main() {
	m := map[Point]string{}
	p := Point{x: 42, y: 5}
	m[p] = "Hello"

	fmt.Println(m)
}
