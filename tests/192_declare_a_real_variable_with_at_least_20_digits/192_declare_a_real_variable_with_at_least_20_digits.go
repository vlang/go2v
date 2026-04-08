package main

import (
	"fmt"
	"math/big"
)

func main() {
	a, _, err := big.ParseFloat("123456789.123456789123465789", 10, 200, big.ToZero)
	if err != nil {
		panic(err)
	}

	fmt.Println(a)
}
