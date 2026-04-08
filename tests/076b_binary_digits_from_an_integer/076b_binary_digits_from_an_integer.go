package main

import (
	"fmt"
	"math/big"
)

func main() {
	x := big.NewInt(13)
	s := fmt.Sprintf("%b", x)

	fmt.Println(s)
}