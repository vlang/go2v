package main

import (
	"fmt"
	"log"
	"strconv"
)

func main() {
	s := "101010100000000011111111"

	if len(s)%8 != 0 {
		log.Fatalf("Length %d is not a multiple of 8: %q", len(s), s)
	}

	n := len(s) / 8
	a := make([]byte, n)
	for i := range a {
		b, err := strconv.ParseInt(s[i*8:i*8+8], 2, 0)
		if err != nil {
			log.Fatal(err)
		}
		a[i] = byte(b)
	}

	fmt.Println(a)
	fmt.Printf("%X", a)
}