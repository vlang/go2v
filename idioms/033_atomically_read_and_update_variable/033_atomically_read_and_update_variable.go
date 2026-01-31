package main

import (
	"fmt"
	"sync"
)

func main() {
	var lock sync.RWMutex
	x := 3

	lock.Lock()
	x = f(x)
	lock.Unlock()

	fmt.Println(x)
}

func f(i int) int {
	return 2 * i
}
