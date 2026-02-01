package main

import "fmt"

func main() {
	m := map[string]int{"one": 1, "two": 2}
	k := "three"
	v := 3

	m[k] = v

	fmt.Println(m)
}
