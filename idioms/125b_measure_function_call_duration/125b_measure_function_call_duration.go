package main

import (
	"fmt"
	"time"
)

func main() {
	t1 := time.Now()
	foo()
	t := time.Since(t1)
	ns := t.Nanoseconds()
	fmt.Printf("%dns\n", ns)
}

func foo() {
	fmt.Println("Hello")
}
