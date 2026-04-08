package main

import (
	"fmt"
	"strings"
)

func main() {
	s := "Let's dance the macarena"

	word := "dance"
	ok := strings.Contains(s, word)
	fmt.Println(ok)

	word = "car"
	ok = strings.Contains(s, word)
	fmt.Println(ok)

	word = "duck"
	ok = strings.Contains(s, word)
	fmt.Println(ok)
}
