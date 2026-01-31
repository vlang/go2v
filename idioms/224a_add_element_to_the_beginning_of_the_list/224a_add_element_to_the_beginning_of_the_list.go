package main

import (
	"fmt"
)

type T int

func main() {
	items := []T{42, 1337}
	var x T = 7
	
	items = append([]T{x}, items...)

	fmt.Println(items)
}