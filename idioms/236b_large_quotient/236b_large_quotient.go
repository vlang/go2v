package main

import (
	"fmt"
	"math/big"
)

func main() {
	a, b := new(big.Int), new(big.Int)
	a.SetString("3559085320938475823508", 10)
	b.SetString("1132039848475763040", 10)

	q := new(big.Rat)
	q.SetFrac(a, b)

	fmt.Println(q)
}
