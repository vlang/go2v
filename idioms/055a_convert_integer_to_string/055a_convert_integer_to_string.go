package main

import (
	"fmt"
	"strconv"
)

func main() {
	var i int = 1234
	s := strconv.Itoa(i)
	fmt.Println(s)
}