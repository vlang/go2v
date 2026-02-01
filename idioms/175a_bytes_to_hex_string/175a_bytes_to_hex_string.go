package main

import (
	"encoding/hex"
	"fmt"
)

func main() {
	a := []byte("Hello")

	s := hex.EncodeToString(a)

	fmt.Println(s)
}
