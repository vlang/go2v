package main

import (
	"fmt"
	"regexp"
)

func main() {
	s := "2021-03-11,linux_amd64"

	re := regexp.MustCompile("[,\\-_]")
	parts := re.Split(s, -1)
	
	fmt.Printf("%q", parts)
}