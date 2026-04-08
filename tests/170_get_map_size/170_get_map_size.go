package main

import "fmt"

func main() {
	mymap := map[string]int{"a": 1, "b": 2, "c": 3}
	n := len(mymap)
	fmt.Println(n)
}
