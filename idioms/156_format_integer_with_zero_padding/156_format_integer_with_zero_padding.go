package main

import (
	"fmt"
)

func main() {
	for _, i := range []int{
		0,
		8,
		64,
		256,
		2048,
	} {
		s := fmt.Sprintf("%03d", i)
		fmt.Println(s)
	}
}
