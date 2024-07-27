package main

type Struct1 struct {
	a int
	b []string
}

func main() {
	foo := Struct1{a:5}
	foo.a = 7
}
