package main

func f(x ...int) {
	if len(x) > 0 {
		println("Present", x[0])
	} else {
		println("Not present")
	}
}

func main() {
	f()
	f(1)
}
