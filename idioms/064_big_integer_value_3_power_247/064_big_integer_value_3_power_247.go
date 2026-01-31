package main

import "fmt"
import "math/big"

func main() {
	x := new(big.Int)
	x.Exp(big.NewInt(3), big.NewInt(247), nil)
	fmt.Println(x)
}
