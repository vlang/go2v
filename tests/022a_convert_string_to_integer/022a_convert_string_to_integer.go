package main

import (
	"fmt"
	"reflect"
	"strconv"
)

func main() {
	// create a string
	s := "123"
	fmt.Println(s)
	fmt.Println("type:", reflect.TypeOf(s))

	// convert string to int
	i, err := strconv.Atoi(s)
	if err != nil {
		panic(err)
	}
	fmt.Println(i)
	fmt.Println("type:", reflect.TypeOf(i))
}
