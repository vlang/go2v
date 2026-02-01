package main

import (
	"fmt"
	"strconv"
)

func main() {
	a := []string{"11", "22", "33"}

	b := make([]int, len(a))
	var err error
	for i, s := range a {
		b[i], err = strconv.Atoi(s)
		if err != nil {
			panic(err)
		}
	}

	fmt.Println(b)
}
