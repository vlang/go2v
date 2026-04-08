package main

import (
	"flag"
	"fmt"
)

var verbose = flag.Bool("v", false, "verbose")

func main() {
	flag.Parse()
	fmt.Println("verbose is", *verbose)
}

// You can't pass a flag value in the Playground.
// Save the source as readflag.go on your computer and try it:
//   go run readflag.go
//   go run readflag.go -v
//   go run readflag.go -v=1
//   go run readflag.go -v=true
//   go run readflag.go -v=0
//   go run readflag.go -v=false