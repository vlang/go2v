package main

import (
	"fmt"
	"image"
)

func main() {
	x1, y1, x2, y2 := 1, 1, 50, 100
	r := image.Rect(x1, y1, x2, y2)

	x, y := 10, 10
	p := image.Pt(x, y)
	b := p.In(r)
	fmt.Println(b)

	x, y = 100, 100
	p = image.Pt(x, y)
	b = p.In(r)
	fmt.Println(b)
}
