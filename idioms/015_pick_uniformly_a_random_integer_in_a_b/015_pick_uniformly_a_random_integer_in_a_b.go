package main

import (
	"fmt"
	"math/rand"
)

func main() {
	x := pick(3, 7)

	// Note that in the Go Playground, time and random don't change very often.
	fmt.Println(x)
}

func pick(a, b int) int {
	return a + rand.Intn(b-a+1)
}
