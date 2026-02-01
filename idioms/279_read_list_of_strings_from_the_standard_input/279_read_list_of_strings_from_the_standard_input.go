package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"log"
	"os"
)

func main() {
	var lines []string
	s := bufio.NewScanner(os.Stdin)
	for s.Scan() {
		line := s.Text()
		lines = append(lines, line)
	}
	if err := s.Err(); err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Read %d lines\n", len(lines))
	fmt.Printf("%q", lines)
}

func init() {
	// Simulate Stdin be replacing it with a given *File
	data := `abc
  22
foo bar  `
	err := ioutil.WriteFile("/tmp/stdin", []byte(data), 0644)
	if err != nil {
		panic(err)
	}
	os.Stdin, err = os.Open("/tmp/stdin")
	if err != nil {
		panic(err)
	}
}
