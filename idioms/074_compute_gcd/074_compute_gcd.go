package main

import "fmt"
import "math/big"

func main() {
	a, b, x := new(big.Int), new(big.Int), new(big.Int)
	a.SetString("6000000000000", 10)
	b.SetString("9000000000000", 10)
	x.GCD(nil, nil, a, b)
	fmt.Println(x)
}
