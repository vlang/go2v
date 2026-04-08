package main

import (
	"fmt"
	"time"
)

func main() {
	ch := make(chan string)

	go func() {
		v := <-ch
		fmt.Printf("Hello, %v\n", v)
	}()

	ch <- "Alan"

	// Make sure the non-main goroutine had the chance to finish.
	time.Sleep(time.Second)
}
