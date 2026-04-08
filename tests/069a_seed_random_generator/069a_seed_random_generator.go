package main

import (
	"fmt"
	"math/rand"
)

func main() {
	var s int64 = 42
	rand.Seed(s)
	fmt.Println(rand.Int())
}
