package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	p(ctx)
}

func p(ctx context.Context) {
	for i := 0; i < 100; i++ {
		select {
		case <-ctx.Done():
			return
		default:
			fmt.Println(i)
			time.Sleep(time.Second)
		}
	}
}