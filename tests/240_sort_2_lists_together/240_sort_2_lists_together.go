package main

import (
	"fmt"
	"sort"
)

type K int
type T string

type sorter struct {
	k []K
	t []T
}

func (s *sorter) Len() int {
	return len(s.k)
}

func (s *sorter) Swap(i, j int) {
	// Swap affects 2 slices at once.
	s.k[i], s.k[j] = s.k[j], s.k[i]
	s.t[i], s.t[j] = s.t[j], s.t[i]
}

func (s *sorter) Less(i, j int) bool {
	return s.k[i] < s.k[j]
}

func main() {
	a := []K{9, 3, 4, 8}
	b := []T{"nine", "three", "four", "eight"}

	sort.Sort(&sorter{
		k: a,
		t: b,
	})

	fmt.Println(a)
	fmt.Println(b)
}