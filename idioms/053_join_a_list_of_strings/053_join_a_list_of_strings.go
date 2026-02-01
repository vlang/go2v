package main

import (
	"fmt"
	"strings"
)

func main() {
	x := []string{"eggs", "butter", "milk"}

	y := strings.Join(x, ", ")

	fmt.Printf("%q", y)
}
