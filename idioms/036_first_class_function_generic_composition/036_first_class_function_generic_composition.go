package main

import "fmt"

func composeIntFuncs(f func(int) int, g func(int) int) func(int) int {
	return func(x int) int {
		return g(f(x))
	}
}

func main() {
	double := func(x int) int {
		return 2 * x
	}
	addTwo := func(x int) int {
		return x + 2
	}
	h := composeIntFuncs(double, addTwo)

	for i := 0; i < 10; i++ {
		fmt.Println(i, h(i), addTwo(double(i)))
	}
}
