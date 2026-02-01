package main

import (
	"fmt"
	"time"
)

func main() {
	// "2006-01-02" is actually a layout. See https://pkg.go.dev/time#Time.String

	t := time.Now().Add(24 * time.Hour).Format("2006-01-02")

	// In the Go Playground, this prints "2009-11-11" because the simulated "current date" is fixed at 2009-11-10.
	fmt.Println(t)
}
