package main

import (
	"fmt"
	"math/big"
)

func main() {
	z := new(big.Int)
	
	z.Binomial(4, 2)
	fmt.Println(z)
	
	z.Binomial(133, 71)
	fmt.Println(z)
}
