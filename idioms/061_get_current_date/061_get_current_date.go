package main

import (
	"fmt"
	"time"
)

func main() {
	d := time.Now()
	fmt.Println("Now is", d)
	// The Playground has a special sandbox, so you may get a Time value fixed in the past.
}