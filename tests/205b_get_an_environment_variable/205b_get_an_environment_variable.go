package main

import (
	"fmt"
	"os"
)

func main() {
	foo := os.Getenv("FOO")
	if foo == "" {
		foo = "none"
	}

	fmt.Println(foo)
}