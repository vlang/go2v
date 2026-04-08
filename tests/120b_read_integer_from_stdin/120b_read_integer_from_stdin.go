package main

import (
	"fmt"
	"io/ioutil"
	"os"
)

// This string simulates the keyboard entry.
var userInput string = `42 017`

func main() {
	var i int
	_, err := fmt.Scanf("%d", &i)
	fmt.Println(i, err)

	var j int
	_, err = fmt.Scanf("%d", &j)
	fmt.Println(j, err)
}

// The Go Playground doesn't actually read os.Stdin, so this
// workaround writes some data on virtual FS in a file, and then
// sets this file as the new Stdin.
//
// Note that the init func is run before main.
func init() {
	err := ioutil.WriteFile("/tmp/stdin", []byte(userInput), 0644)
	if err != nil {
		panic(err)
	}
	fileIn, err := os.Open("/tmp/stdin")
	if err != nil {
		panic(err)
	}
	os.Stdin = fileIn
}
