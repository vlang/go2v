package main

func main() {
	var s = []int{}

	s = append(s, 1)

	s = append(s, 2, 3, 4)

	a := []int{4, 5, 6}
	b := []int{1, 2, 3}
	b = append(b, a...)
}
