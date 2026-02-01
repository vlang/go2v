package main

import (
	"fmt"
	"math/rand"
)

func main() {
	var s int64 = 42
	r := rand.New(rand.NewSource(s))
	fmt.Println(r.Int())
}
