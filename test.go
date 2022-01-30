package main

import (
	"fmt"
	"io"
)

type Ok = int

type Oui struct {
	a int
	b string
}

type Non struct {
	c []int
	d []Oui
}

const LOL = 123

func main() {
	fmt.Println("Hello, World!")
	io.EOF
	//println(ok())
}

func ok() int {
	return 1
}
