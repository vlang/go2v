package main

import "fmt"

type Oui struct {
	a int
	b string
}

type Non struct {
	c int
	d string
}

const LOL = 123

func main() {
	fmt.Println("Hello, World!")
	//println(ok())
}

func ok() int {
	return 1
}
