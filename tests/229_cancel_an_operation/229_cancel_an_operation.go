package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	go p(ctx)
	time.Sleep(3 * time.Second)
	cancel()
	time.Sleep(3 * time.Second)
}

func p(ctx context.Context) {
	for i := 0; i < 10; i++ {
		select {
		case <-ctx.Done():
			return
		default:
			fmt.Println(i)
			time.Sleep(time.Second)
		}
	}
}