package main

import (
	"fmt"
)

type T int

func main() {
	items := []T{42, 1337}
	var x T = 7

	items = append(items, x)
	copy(items[1:], items)
	items[0] = x

	fmt.Println(items)
}
