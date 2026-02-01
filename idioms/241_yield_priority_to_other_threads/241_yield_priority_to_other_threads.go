package main

import (
	"fmt"
	"runtime"
	"time"
)

func main() {
	go fmt.Println("aaa")
	go fmt.Println("bbb")
	go fmt.Println("ccc")
	go fmt.Println("ddd")
	go fmt.Println("eee")

	runtime.Gosched()
	busywork()

	time.Sleep(100 * time.Millisecond)
}

func busywork() {
	fmt.Println("main")
}