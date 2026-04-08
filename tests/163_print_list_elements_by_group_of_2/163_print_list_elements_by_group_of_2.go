package main

import (
	"fmt"
)

func main() {
	list := []string{"a", "b", "c", "d", "e", "f"}

	for i := 0; i+1 < len(list); i += 2 {
		fmt.Println(list[i], list[i+1])
	}
}
