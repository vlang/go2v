package main

import "fmt"
import "math/big"

func exp(x *big.Int, n int) *big.Int {
	nb := big.NewInt(int64(n))
	var z big.Int
	z.Exp(x, nb, nil)
	return &z
}

func main() {
	x := big.NewInt(3)
	n := 5
	z := exp(x, n)
	fmt.Println(z)
}
