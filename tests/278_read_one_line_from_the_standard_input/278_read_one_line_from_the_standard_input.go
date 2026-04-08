package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"log"
	"os"
)

func main() {
	s := bufio.NewScanner(os.Stdin)
	if ok := s.Scan(); !ok {
		log.Fatal(s.Err())
	}
	line := s.Text()

	fmt.Printf("Read line: %q\n", line)
}

func init() {
	// Simulate Stdin be replacing it with a given *File
	err := ioutil.WriteFile("/tmp/stdin", []byte(`abc
  22
foo bar  `), 0644)
	if err != nil {
		panic(err)
	}
	os.Stdin, err = os.Open("/tmp/stdin")
	if err != nil {
		panic(err)
	}
}