package main

import (
	"fmt"
	"strings"
)

func main() {
	s := "café-society"
	w := "society"

	t := strings.TrimSuffix(s, w)

	fmt.Println(t)
}
