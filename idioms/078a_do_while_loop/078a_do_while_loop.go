package main

import (
	"fmt"
	"math/rand"
)

func main() {
	for {
		x := rollDice()
		fmt.Println("Got", x)
		if x == 3 {
			break
		}

	}
}

func rollDice() int {
	return 1 + rand.Intn(6)
}
