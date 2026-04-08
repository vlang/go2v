package main

import "fmt"

func exp(x, n int) int {
	switch {
	case n == 0:
		return 1
	case n == 1:
		return x
	case n%2 == 0:
		return exp(x*x, n/2)
	default:
		return x * exp(x*x, (n-1)/2)
	}
}

func main() {
	fmt.Println(exp(3, 5))
}