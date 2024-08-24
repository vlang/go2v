package main

type Ok struct{}

func main() {
	a := []byte{1, 2, 3}
	b := []int{1, 2, 3}
	c := []string{"a", "b", "c"}
	d := []Ok{Ok{}, Ok{}, Ok{}}
	e := []int32{1, 2, 3}
}
