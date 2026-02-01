package main

import (
	"fmt"
	"math/big"
)

func main() {
	var a int64 = 12345678
	var b int64 = 98765432109876

	q := big.NewRat(a, b)

	fmt.Println(q)
}
