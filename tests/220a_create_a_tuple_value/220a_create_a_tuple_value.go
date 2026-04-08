package main

import (
	"fmt"
)

func main() {

	t := []interface{}{
		2.5,
		"hello",
		make(chan int),
	}

	fmt.Println(t)
}
