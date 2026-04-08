package main

func main() {
	f()
}

func f() {
	type t struct {
		s string
		n []int
	}

	v := t{
		s: "Hello, world!",
		n: []int{1, 4, 9, 16, 25},
	}

	// Pretend to use v (otherwise this is a compile error)
	_ = v

	// When f exits, v and all its fields are garbage-collected, recursively
}
