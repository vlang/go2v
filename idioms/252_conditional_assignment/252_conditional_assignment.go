package main

import (
	"fmt"
)

func main() {
	var x string
	if condition() {
		x = "a"
	} else {
		x = "b"
	}

	fmt.Println(x)
}

func condition() bool {
	return "Scorates" == "dog"
}
