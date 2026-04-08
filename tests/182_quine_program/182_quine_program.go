package main

import "fmt"

func main() {
	fmt.Printf("%s%c%s%c\n", s, 0x60, s, 0x60)
}

var s = `package main

import "fmt"

func main() {
	fmt.Printf("%s%c%s%c\n", s, 0x60, s, 0x60)
}

var s = `
