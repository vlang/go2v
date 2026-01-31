package main

import (
	"fmt"
	"math/big"
)

func main() {
	a, b := big.NewInt(230), big.NewInt(42)
	c := new(big.Int)
	c.Xor(a, b)

	fmt.Printf("a is %12b\n", a)
	fmt.Printf("b is %12b\n", b)
	fmt.Printf("c is %12b\n", c)
	fmt.Println("c ==", c)
}
