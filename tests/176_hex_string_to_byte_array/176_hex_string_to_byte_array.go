package main

import (
	"encoding/hex"
	"fmt"
	"log"
)

func main() {
	s := "48656c6c6f"

	a, err := hex.DecodeString(s)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(a)
	fmt.Println(string(a))
}
