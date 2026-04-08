package main

import "fmt"
import "math/big"

func main() {
	a, b, gcd, x := new(big.Int), new(big.Int), new(big.Int), new(big.Int)
	a.SetString("6000000000000", 10)
	b.SetString("9000000000000", 10)
	gcd.GCD(nil, nil, a, b)
	x.Div(a, gcd).Mul(x, b)
	fmt.Println(x)
}