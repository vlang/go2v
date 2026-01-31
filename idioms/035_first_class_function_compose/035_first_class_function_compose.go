package main

import "fmt"
import "strconv"

func compose(f func(A) B, g func(B) C) func(A) C {
	return func(x A) C {
		return g(f(x))
	}
}

func main() {
	squareFromStr := compose(str2int, square)
	fmt.Println(squareFromStr("12"))
}

type A string
type B int
type C int

func str2int(a A) B {
	b, _ := strconv.ParseInt(string(a), 10, 32)
	return B(b)
}

func square(b B) C {
	return C(b * b)
}