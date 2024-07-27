package main

import "fmt"

type insertionModeStack []int

func (s *insertionModeStack) foo() (im int) {
	i := len(*s)
	im = (*s)[i-1]
	*s = (*s)[:i-1]
	a := &i
	fmt.Println(*a)
	return im
}
