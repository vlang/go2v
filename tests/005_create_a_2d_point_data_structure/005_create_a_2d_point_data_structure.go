package main

import "fmt"

type Point struct {
	x, y float64
}

func main() {
	p1 := Point{}
	p2 := Point{2.1, 2.2}
	p3 := Point{
		y: 3.1,
		x: 3.2,
	}
	p4 := &Point{
		x: 4.1,
		y: 4.2,
	}

	fmt.Println(p1)
	fmt.Println(p2)
	fmt.Println(p3)
	fmt.Println(p4)
}
