package main

import "fmt"

func main() {
	buf := make([]byte, 1000000)

	for i, b := range buf {
		if b != 0 {
			fmt.Println("Found unexpected value", b, "at position", i)
		}
	}
	fmt.Println("Buffer was correctly initialized with zero values.")
}