package main

type A struct {
	AA int
}

type B struct {
	a  int
	BB int
	A
}

func main() {
	b := B{}
	b.BB = 2
	b.a = 3
	b.A.AA = 4
	println(b.A)
}
