package main

import (
	"fmt"
	"os"
	"reflect"
)

func main() {
	var x interface{}

	x = "Hello"
	fmt.Println(reflect.TypeOf(x))

	x = 4
	fmt.Println(reflect.TypeOf(x))

	x = os.NewFile(0777, "foobar.txt")
	fmt.Println(reflect.TypeOf(x))
}
