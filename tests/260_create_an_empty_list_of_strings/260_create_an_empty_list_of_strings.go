package main

import (
	"fmt"
)

func main() {
	var items []string

	fmt.Println("items has", len(items), "elements")
	fmt.Printf("items is %q\n", items)

	items = append(items, "foobar")

	fmt.Println("items has", len(items), "elements")
	fmt.Printf("items is %q\n", items)
}
