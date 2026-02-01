package main

import (
	"fmt"
	"time"
)

func main() {
	ts := int64(1451606400)
	d := time.Unix(ts, 0)

	fmt.Println(d)
}
