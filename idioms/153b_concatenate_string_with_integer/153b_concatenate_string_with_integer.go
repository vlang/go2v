package main

import (
	"fmt"
	"strconv"
)

func main() {
	s := "Hello"
	i := 123

	t := s + strconv.Itoa(i)

	fmt.Println(t)
}
