package main

import (
	"fmt"
	"strconv"
)

func main() {
	if strconv.IntSize == 32 {
		f32()
	}
	if strconv.IntSize == 64 {
		f64()
	}
}

func f32() {
	fmt.Println("I am 32-bit")
}

func f64() {
	fmt.Println("I am 64-bit")
}
