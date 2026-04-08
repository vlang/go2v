package main

import (
	"fmt"
	"math/rand"
	"time"
)

func main() {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	// Well, the playground date is actually fixed in the past, and the
	// output is cached.
	// But if you run this on your workstation, the output will vary.
	fmt.Println(r.Intn(999))
}
