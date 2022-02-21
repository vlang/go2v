package main

import "fmt"

func main() {
	fmt.Println("Hello World")

	strings := []string{"hello", "world"}
	for idx := range strings {
		fmt.Println(idx)
	}
}
