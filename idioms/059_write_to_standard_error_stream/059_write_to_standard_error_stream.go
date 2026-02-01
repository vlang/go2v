package main

import (
	"fmt"
	"os"
)

func main() {
	x := -2
	fmt.Fprintln(os.Stderr, x, "is negative")
}
