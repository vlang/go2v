package main

import (
	"fmt"
	"math/rand"
)

func main() {
	for done := false; !done; {
		x := rollDice()
		fmt.Println("Got", x)
		done = x == 3
	}
}

func rollDice() int {
	return 1 + rand.Intn(6)
}
