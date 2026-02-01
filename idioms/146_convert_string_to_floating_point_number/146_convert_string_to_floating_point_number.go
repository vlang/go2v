package main

import (
	"fmt"
	"strconv"
)

func main() {
	s := "3.1415926535"

	f, err := strconv.ParseFloat(s, 64)
	fmt.Printf("%T, %v, err=%v\n", f, f, err)
}

//
// http://www.programming-idioms.org/idiom/146/convert-string-to-floating-point-number/1819/go
//
