package main

import (
	"fmt"
)

func main() {
	fmt.Print("You're")
	switch age := 27; age {
	case 18:
		fmt.Println(" of age")
	case 10:
		fmt.Println(" a child")
	default:
		fmt.Println(".. I don't know my program is pretty dumb :/")
	}
}
