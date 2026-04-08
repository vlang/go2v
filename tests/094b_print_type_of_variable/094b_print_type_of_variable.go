package main

import (
	"fmt"
	"os"
)

func main() {
	var x interface{}

	x = "Hello"
	fmt.Printf("%T", x)
	fmt.Println()

	x = 4
	fmt.Printf("%T", x)
	fmt.Println()

	x = os.NewFile(0777, "foobar.txt")
	fmt.Printf("%T", x)
	fmt.Println()
}
