package main

import (
	"fmt"
	"math/rand"
	"time"
)

func f(i int) {
	d := rand.Int() % 10000
	time.Sleep(time.Duration(d))
	fmt.Printf("Hello %v\n", i)
}

func main() {
	for i := 1; i <= 1000; i++ {
		go f(i)
	}

	time.Sleep(4 * time.Second)
}
