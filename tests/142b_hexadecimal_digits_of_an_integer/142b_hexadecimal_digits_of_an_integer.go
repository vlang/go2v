package main

import (
	"fmt"
	"math/big"
)

func main() {
	x := big.NewInt(999)
	s := fmt.Sprintf("%x", x)

	fmt.Println(s)
}
