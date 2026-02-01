package main

import (
	"fmt"
)

type Suit int

const (
  Spades Suit = iota
  Hearts
  Diamonds
  Clubs
)

func main() {
	fmt.Printf("Hearts has type %T and value %d", Hearts, Hearts)
}
