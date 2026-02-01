package main

import (
	"fmt"
	"math/bits"
)

func main() {
	var n uint = 112

	t := bits.TrailingZeros(n)

	fmt.Println(t)
}
