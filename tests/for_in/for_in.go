package main

import "fmt"

func main() {
	strings := []string{"hello", "world"}
	for idx, el := range strings {
		fmt.Println(idx, el)
		//fmt.Println(idx, strings[idx]) //TODO: support this
	}
	for idx := range strings {
		fmt.Println(idx)
	}
	for range strings {
		fmt.Println("hello")
	}
}
