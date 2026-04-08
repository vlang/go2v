package main

import (
	"fmt"
)

func main() {
	items := []int{11, 22, 33}

	for _, x := range items {
		doSomething(x)
	}
}

func doSomething(i int) {
	fmt.Println(i)
}
