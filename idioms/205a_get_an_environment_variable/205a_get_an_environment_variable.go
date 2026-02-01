package main

import (
	"fmt"
	"os"
)

func main() {
	foo, ok := os.LookupEnv("FOO")
	if !ok {
		foo = "none"
	}

	fmt.Println(foo)
}