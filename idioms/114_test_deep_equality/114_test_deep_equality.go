package main

import (
	"fmt"
	"reflect"
)

func main() {
	x := Foo{9, "Hello", []bool{false, true}, map[int]float64{1: 1.0, 2: 2.0}, &Bar{"Babar"}}

	list := []Foo{
		{9, "Bye", []bool{false, true}, map[int]float64{1: 1.0, 2: 2.0}, &Bar{"Babar"}},
		{9, "Hello", []bool{false, false}, map[int]float64{1: 1.0, 2: 2.0}, &Bar{"Babar"}},
		{9, "Hello", []bool{false, true}, map[int]float64{1: 3.0, 2: 2.0}, &Bar{"Babar"}},
		{9, "Hello", []bool{false, true}, map[int]float64{1: 1.0, 5: 2.0}, &Bar{"Babar"}},
		{9, "Hello", []bool{false, true}, map[int]float64{1: 1.0, 2: 2.0}, &Bar{"Batman"}},
		{9, "Hello", []bool{false, true}, map[int]float64{1: 1.0, 2: 2.0}, &Bar{"Babar"}},
	}

	for i, y := range list {
		b := reflect.DeepEqual(x, y)
		if b {
			fmt.Println("x deep equals list[", i, "]")

		} else {
			fmt.Println("x doesn't deep equal list[", i, "]")
		}
	}
}

type Foo struct {
	int
	str     string
	bools   []bool
	mapping map[int]float64
	bar     *Bar
}

type Bar struct {
	name string
}
