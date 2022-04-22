package main

type A struct {
	AA int
}

type B struct {
	BB int
	A
}

func main() {
	b := B{}
	b.BB = 2
	b.A.AA = 4 //TODO: should transform to `b.AA.aa = 4`
}
