package main

import (
	"fmt"
	"strings"
)

func main() {
	s := "Romaromamam"
	t := "mam"

	x := strings.Count(s, t)

	fmt.Println(x)
}
