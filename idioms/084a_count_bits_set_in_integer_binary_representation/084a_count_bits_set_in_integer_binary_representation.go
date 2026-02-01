package main

import "fmt"

func PopCountUInt64(i uint64) (c int) {
	// bit population count, see
	// http://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
	i -= (i >> 1) & 0x5555555555555555
	i = (i>>2)&0x3333333333333333 + i&0x3333333333333333
	i += i >> 4
	i &= 0x0f0f0f0f0f0f0f0f
	i *= 0x0101010101010101
	return int(i >> 56)
}

func PopCountUInt32(i uint32) (n int) {
	// bit population count, see
	// http://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
	i -= (i >> 1) & 0x55555555
	i = (i>>2)&0x33333333 + i&0x33333333
	i += i >> 4
	i &= 0x0f0f0f0f
	i *= 0x01010101
	return int(i >> 24)
}

func main() {
	for i := uint64(0); i < 16; i++ {
		c := PopCountUInt64(i)
		fmt.Printf("%4d %04[1]b %d\n", i, c)
	}

	for i := uint32(0); i < 16; i++ {
		c := PopCountUInt32(i)
		fmt.Printf("%4d %04[1]b %d\n", i, c)
	}
}
