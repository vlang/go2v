package main

import (
	"fmt"
)

func main() {
	s := "Hello"
	i := 123

	t := fmt.Sprintf("%s%d", s, i)

	fmt.Println(t)
}
