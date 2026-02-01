package main

import (
	"fmt"
	"io/ioutil"
	"os"
)

func main() {
	for _, filepath := range []string{
		"/tmp/foo.txt",
		"/tmp/bar.txt",
		"/tmp/foo.txt",
	} {
		err := os.Remove(filepath)
		if err == nil {
			fmt.Println("Removed", filepath)
		} else {
			fmt.Fprintln(os.Stderr, err)
		}
	}
}

func init() {
	err := ioutil.WriteFile("/tmp/foo.txt", []byte(`abc`), 0644)
	if err != nil {
		panic(err)
	}
}
