package main

import (
	"fmt"
	"reflect"
)

func main() {
	x := 5
	y := float64(x)

	fmt.Println(y)
	fmt.Printf("%.2f\n", y)
	fmt.Println(reflect.TypeOf(y))
}
