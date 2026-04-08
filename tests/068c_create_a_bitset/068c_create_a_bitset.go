package main

import (
	"fmt"
)

func main() {
	const n = 1024

	x := NewBitset(n)

	x.SetBit(13)
	x.SetBit(42)
	x.ClearBit(13)

	for _, y := range []int{13, 42} {
		fmt.Println("x has bit", y, "set to", x.GetBit(y))
	}
}

type Bitset []uint64

func NewBitset(n int) Bitset {
	return make(Bitset, (n+63)/64)
}

func (b Bitset) GetBit(index int) bool {
	pos := index / 64
	j := index % 64
	return (b[pos] & (uint64(1) << j)) != 0
}

func (b Bitset) SetBit(index int) {
	pos := index / 64
	j := index % 64
	b[pos] |= (uint64(1) << j)
}

func (b Bitset) ClearBit(index int) {
	pos := index / 64
	j := index % 64
	b[pos] ^= (uint64(1) << j)
}
