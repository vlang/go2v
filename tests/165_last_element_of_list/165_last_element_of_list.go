package main

import (
	"fmt"
)

func main() {
	items := []string{ "what", "a", "mess" }
	
	x := items[len(items)-1]

	fmt.Println(x)
}
