package main

import (
	"fmt"
	"reflect"
)

func main() {
	var t T
	tType := reflect.TypeOf(t)
	n := tType.Size()

	fmt.Println("A", tType, "object is", n, "bytes.")
}

type Person struct {
	FirstName string
	Age       int
}

// T is a type alias, to stick to the idiom statement.
// T has the same memory footprint per value as Person.
type T Person
