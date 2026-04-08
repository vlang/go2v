package main

import (
	"fmt"
	"time"
)

func main() {
	d1 := time.Now()
	d2 := time.Date(2020, time.November, 10, 23, 0, 0, 0, time.UTC)

	b := d1.Before(d2)

	fmt.Println(b)
}
