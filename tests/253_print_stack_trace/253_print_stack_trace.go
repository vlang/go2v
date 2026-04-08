package main

import (
	"fmt"
	"runtime/debug"
)

func main() {
	fmt.Println("Start")
	myFancyFunc()
	fmt.Println("The end.")
}

func myFancyFunc() {
	debug.PrintStack()
}
