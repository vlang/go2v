package main

import (
	"fmt"
)

type T byte

func main() {
	n := 10_000_000
	a := make([]T, n)
	fmt.Println(len(a))
}
