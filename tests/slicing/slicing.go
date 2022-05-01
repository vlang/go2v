package main

func main() {
	a := []int{0, 1, 2, 3}
	s := a[1:3]
	s = a[:2]
	s = a[2:]
	s = a[:]
}
