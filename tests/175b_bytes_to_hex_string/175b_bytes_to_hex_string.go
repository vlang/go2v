package main

import (
	"fmt"
)

func main() {
	a := []byte("Hello")

	s := fmt.Sprintf("%x", a)

	fmt.Println(s)
}
