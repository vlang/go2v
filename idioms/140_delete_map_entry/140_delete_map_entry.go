package main

import (
	"fmt"
)

func main() {
	m := map[string]int{
		"uno":  1,
		"dos":  2,
		"tres": 3,
	}

	delete(m, "dos")
	delete(m, "cinco")

	fmt.Println(m)
}