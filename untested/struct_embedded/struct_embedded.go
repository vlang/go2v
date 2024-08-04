package main

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
