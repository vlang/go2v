package main

import "fmt"

func main() {
	finish := func(name string) {
		fmt.Println("My job here is done. Good bye " + name)
	}
	finish("Go")
}
