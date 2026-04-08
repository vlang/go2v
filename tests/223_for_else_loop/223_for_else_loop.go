package main

import (
	"fmt"
)

func main() {
	items := []string{"foo", "bar", "baz", "qux"}

	for _, item := range items {
		if item == "baz" {
			fmt.Println("found it")
			goto forelse
		}
	}
	{
		fmt.Println("never found it")
	}
        forelse:
}
