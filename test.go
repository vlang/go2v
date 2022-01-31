package main

import (
	"fmt"
	"io"
)

type Type1 = int
type Type2 = []string
type Type3 = []Struct1

type Struct1 struct {
	a int
	b string
}

type Struct2 struct {
	c []int
	d []Struct1
	e Struct3
}

type Struct3 struct {
	f int
}

const STRUCT_UPPERCASE_TO_HANDLE = 123
const struct1 = "dsfsdfs"
const struct2 = 'a'
const struct3 = true

func main() {
	fmt.Println("Hello, World!")
	fmt.Println(io.EOF)
	//println(ok())
}

func func1() int {
	return 1
}
