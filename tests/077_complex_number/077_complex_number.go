package main

import (
	"fmt"
	"reflect"
)

func main() {
	x := 3i - 2
	x *= 1i

	fmt.Println(x)
	fmt.Print(reflect.TypeOf(x))
}
