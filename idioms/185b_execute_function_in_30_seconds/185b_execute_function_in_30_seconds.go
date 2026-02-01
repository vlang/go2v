package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println("Scheduling f(42)")

	go func() {
		time.Sleep(3 * time.Second)
		f(42)
	}()

	// Poor man's waiting of completion of f.
	// Don't do this in prod, use proper synchronization instead.
	time.Sleep(4 * time.Second)
}

func f(i int) {
	fmt.Println("Received", i)
}
