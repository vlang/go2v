package main

import "fmt"

func main() {
	for i := 1; i < 5; i += 1 {
		fmt.Println("Hi buddy")
	}
	i := 0
	for ; i < 5; i += 1 {
		fmt.Println("Hi buddy", i)
	}
	for j := 1; j < 5; {
		fmt.Println("Hi buddy")
		j++
	}
}
