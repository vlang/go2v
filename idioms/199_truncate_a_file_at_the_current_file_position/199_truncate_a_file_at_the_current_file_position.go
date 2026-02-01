package main

import (
	"fmt"
	"io/ioutil"
	"os"
)

const F = "/tmp/data.txt"

func init() {
	err := ioutil.WriteFile(F, []byte("abcdefghij"), 0644)
	if err != nil {
		panic(err)
	}
}

func main() {
	var position int64 = 5

	err := os.Truncate(F, position)
	if err != nil {
		panic(err)
	}

	buffer, err := ioutil.ReadFile(F)
	if err != nil {
		panic(err)
	}

	fmt.Printf("%s has length %d and contents %q\n", F, len(buffer), buffer)
}
