package main

import (
	"fmt"
	"strings"
)

func main() {
	x := "été chaud"

	{
		y := "chaud"
		i := strings.Index(x, y)
		fmt.Println(i)
	}

	{
		y := "froid"
		i := strings.Index(x, y)
		fmt.Println(i)
	}
}
