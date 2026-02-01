package main

import (
	"fmt"
	"io/ioutil"
	"os"
)

func main() {
	err := printSize("file.txt")
	if err != nil {
		panic(err)
	}
}

func printSize(path string) error {
	info, err := os.Stat(path)
	if err != nil {
		return err
	}
	x := info.Size()

	fmt.Println(x)
	return nil
}

func init() {
	// The file will only contains the characters "Hello", no newlines.
	buffer := []byte("Hello")
	err := ioutil.WriteFile("file.txt", buffer, 0644)
	if err != nil {
		panic(err)
	}
}
