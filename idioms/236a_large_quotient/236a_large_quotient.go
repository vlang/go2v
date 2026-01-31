package main

import (
	"fmt"
	"math/big"
)

func main() {
	q := new(big.Rat)
	q.SetString("3559085320938475823508/1132039848475763040")
	fmt.Println(q)
}