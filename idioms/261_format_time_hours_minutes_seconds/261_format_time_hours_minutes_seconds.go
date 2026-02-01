package main

import (
	"fmt"
	"time"
)

func main() {
	d := time.Now()
	x := d.Format("15:04:05")
	fmt.Println(x)

	// The output may be "23:00:00" because the Playground's clock is fixed in the past.
}
