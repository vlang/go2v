package main

import (
	"fmt"
)

func main() {
	str := "baz"

	switch str {
	case "foo":
		foo()
	case "bar":
		bar()
	case "baz":
		baz()
	case "barfl":
		barfl()
	}
}

func foo() {
	fmt.Println("Called foo")
}

func bar() {
	fmt.Println("Called bar")
}

func baz() {
	fmt.Println("Called baz")
}

func barfl() {
	fmt.Println("Called barfl")
}
