package main

import (
	"fmt"
)

func main() {
	items := []string{"banana", "apple", "kiwi"}
	fmt.Println(items)

	items = items[:len(items)-1]
	fmt.Println(items)
}
