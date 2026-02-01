package main

import (
	"fmt"
	"os"
)

func main() {
	dir, err := os.Getwd()
	fmt.Println(dir, err)
}
