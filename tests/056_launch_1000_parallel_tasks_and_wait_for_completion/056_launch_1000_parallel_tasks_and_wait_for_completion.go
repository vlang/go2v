package main

import (
	"fmt"
	"math/rand"
	"sync"
	"time"
)

func f(i int) {
	d := rand.Int() % 10000
	time.Sleep(time.Duration(d))
	fmt.Printf("Hello %v\n", i)
}

func main() {
	var wg sync.WaitGroup
	wg.Add(1000)
	for i := 1; i <= 1000; i++ {
		go func(i int) {
			f(i)
			wg.Done()
		}(i)
	}
	wg.Wait()
	fmt.Println("Finished")
}