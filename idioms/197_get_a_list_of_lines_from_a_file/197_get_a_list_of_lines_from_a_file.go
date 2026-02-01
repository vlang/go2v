package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"strings"
)

func readLines(path string) ([]string, error) {
	b, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}
	lines := strings.Split(string(b), "\n")
	return lines, nil
}

func main() {
	lines, err := readLines("/tmp/file1")
	if err != nil {
		log.Fatalln(err)
	}

	for i, line := range lines {
		fmt.Printf("line %d: %s\n", i, line)
	}
}

func init() {
	data := []byte(`foo
bar
baz`)
	err := ioutil.WriteFile("/tmp/file1", data, 0644)
	if err != nil {
		log.Fatalln(err)
	}
}