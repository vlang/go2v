package main

import "fmt"

func main() {
	k := 0
	for {
		fmt.Println("Hello, playground")
		k++
		if k == 5 {
			break
		}
	}
}