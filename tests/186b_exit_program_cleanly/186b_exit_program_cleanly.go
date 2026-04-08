package main

import (
	"fmt"
	"os"
)

func main() {
	process1()
	process2()
	process3()
}

func process1() {
	fmt.Println("process 1")
}

func process2() {
	fmt.Println("process 2")
	defer fmt.Println("A")
	defer os.Exit(0)
	defer fmt.Println("B")
	fmt.Println("C")
}

func process3() {
	fmt.Println("process 3")
}
