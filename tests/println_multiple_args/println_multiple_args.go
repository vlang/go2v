package main

import "fmt"

func main() {
	strings := []string{"hello", "world"}
	for idx, el := range strings {
		fmt.Println(idx, el)
		fmt.Println(idx, strings[idx])
	}
}
