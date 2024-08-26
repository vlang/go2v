package main

func two_fn() (int, int) {
	return 1, 2
}

func main() {
	a, b := 1, 2
	c, d := two_fn()
}
