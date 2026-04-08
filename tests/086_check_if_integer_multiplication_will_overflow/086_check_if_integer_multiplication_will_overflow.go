package main

import (
	"fmt"
)

func multiplyWillOverflow(x, y uint64) bool {
	if x <= 1 || y <= 1 {
		return false
	}
	d := x * y
	return d/y != x
}

func main() {
	{
		var x, y uint64 = 2345, 6789
		if multiplyWillOverflow(x, y) {
			fmt.Println(x, "*", y, "overflows")
		} else {
			fmt.Println(x, "*", y, "doesn't overflow")
		}
	}
	{
		var x, y uint64 = 2345678, 9012345
		if multiplyWillOverflow(x, y) {
			fmt.Println(x, "*", y, "overflows")
		} else {
			fmt.Println(x, "*", y, "doesn't overflow")
		}
	}
	{
		var x, y uint64 = 2345678901, 9012345678
		if multiplyWillOverflow(x, y) {
			fmt.Println(x, "*", y, "overflows")
		} else {
			fmt.Println(x, "*", y, "doesn't overflow")
		}
	}
}
