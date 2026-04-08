package main

import (
	"fmt"
	"math/big"
)

func main() {
	var x *big.Int = new(big.Int)

	x.SetBit(x, 42, 1)

	for _, y := range []int{13, 42} {
		fmt.Println("x has bit", y, "set to", x.Bit(y))
	}
}
