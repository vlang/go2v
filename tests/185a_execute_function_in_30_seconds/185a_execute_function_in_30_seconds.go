package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println("Scheduling f(42)")

	timer := time.AfterFunc(
		3*time.Second,
		func() {
			f(42)
		})

	// This time.Timer could be used to cancel the call.
	_ = timer

	// Poor man's waiting of completion of f.
	// Don't do this in prod, use proper synchronization instead.
	time.Sleep(4 * time.Second)
}

func f(i int) {
	fmt.Println("Received", i)
}
