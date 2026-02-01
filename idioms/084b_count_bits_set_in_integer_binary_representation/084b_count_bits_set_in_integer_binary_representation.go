package main

import (
	"fmt"
	"math/bits"
)

func main() {
	for i := uint(0); i < 16; i++ {
		c := bits.OnesCount(i)
		fmt.Printf("%4d %04[1]b %d\n", i, c)
	}
}
