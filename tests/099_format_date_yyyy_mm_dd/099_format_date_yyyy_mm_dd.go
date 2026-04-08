package main

import (
	"fmt"
	"time"
)

func main() {
	d := time.Now()
	x := d.Format("2006-01-02")
	fmt.Println(x)

	// The output may be "2009-11-10" because the Playground's clock is fixed in the past.
}