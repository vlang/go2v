package main

import "fmt"

func main() {
	go func() {
		fmt.Println("Hello World")
	}()
	go funcA()
}

func funcA() {
}
