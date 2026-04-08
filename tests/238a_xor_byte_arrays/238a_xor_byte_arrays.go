package main

import (
	"fmt"
)

func main() {
	a, b := []byte("Hello"), []byte("world")

	c := make([]byte, len(a))
	for i := range a {
		c[i] = a[i] ^ b[i]
	}

	fmt.Printf("a is %08b\n", a)
	fmt.Printf("b is %08b\n", b)
	fmt.Printf("c is %08b\n", c)
	fmt.Println("c ==", c)
	fmt.Printf("c as string would be %q\n", string(c))
}
