package main

import (
	"fmt"
	"strings"
)

func main() {
	s := "café-society"
	p := "café"

	t := strings.TrimPrefix(s, p)

	fmt.Println(t)
}
