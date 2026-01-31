package main

import (
	"fmt"
)

func main() {
	var a, b, c T = "This", "is", "wonderful"

	items := []T{a, b, c}

	fmt.Println(items)
}

type T string
