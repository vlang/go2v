package main

import "fmt"
import "math/big"

func main() {
	var i int = 1234
	s := fmt.Sprintf("%d", i)
	fmt.Println(s)

	var j int = 5678
	s = fmt.Sprintf("%d", j)
	fmt.Println(s)

	var k *big.Int = big.NewInt(90123456)
	s = fmt.Sprintf("%d", k)
	fmt.Println(s)
}