package main

import "fmt"

func main() {
	mymap := map[string]int{
		"one":   1,
		"two":   2,
		"three": 3,
		"four":  4,
	}

	for k, x := range mymap {
		fmt.Println("Key =", k, ", Value =", x)
	}
}