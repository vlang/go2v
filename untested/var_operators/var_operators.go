package main

type Ok struct {
	a int
}

func main() {
	ok := Ok{}
	sum := 0
	sum += 1
	ok.a /= 2
}
