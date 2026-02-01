package main

import (
	"flag"
	"fmt"
)

var country = flag.String("country", "Canada", "user home country")

func main() {
	flag.Parse()
	fmt.Println("country is", *country)
}

// You can't pass a flag value in the Playground.
// Save the source as readflag.go on your computer and try it:
//   go run readflag.go
//   go run readflag.go -v=France
//   go run readflag.go -v France
