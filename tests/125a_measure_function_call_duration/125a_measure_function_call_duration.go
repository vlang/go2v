package main

import (
	"fmt"
	"time"
)

func main() {
	t1 := time.Now()
	foo()
	t := time.Since(t1)
	ns := int64(t / time.Nanosecond)

	// Note that the clock is fixed in the Playground, so the resulting duration is always zero
	fmt.Printf("%dns\n", ns)
}

func foo() {
	fmt.Println("Hello")
}
