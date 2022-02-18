package main

func main() {
	ok := Test1{}
	ok.a = Test2{}
}

type Test1 struct {
	a Test2
}

type Test2 struct{}
