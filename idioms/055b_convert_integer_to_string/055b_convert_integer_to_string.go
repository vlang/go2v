package main

import (
	"fmt"
	"strconv"
)

func main() {
	var i int64 = 1234
	s := strconv.FormatInt(i, 10)
	fmt.Println(s)
}
