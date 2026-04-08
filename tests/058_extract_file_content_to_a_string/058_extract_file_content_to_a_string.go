package main

import "fmt"
import "io/ioutil"

func main() {
	f := "data.txt"
	b, err := ioutil.ReadFile(f)
	if err != nil {
		panic(err)
	}
	lines := string(b)

	fmt.Println(lines)
}

// Create file in fake FS of the Playground. init is executed before main.
func init() {
	err := ioutil.WriteFile("data.txt", []byte(`Un
Dos
Tres`), 0644)
	if err != nil {
		panic(err)
	}
}
