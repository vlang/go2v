package main

import (
	"fmt"
	"strings"
)

func main() {
	x := "oink oink oink"
	y := "oink"
	z := "moo"
	x2 := strings.Replace(x, y, z, -1)
	fmt.Println(x2)
}
