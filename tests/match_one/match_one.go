package main

import "fmt"

func main() {
	variable := "uppercase"
	switch variable {
	case "a", "b", "c", "d":
		fmt.Println("a, b, c, or d")
	}
}
