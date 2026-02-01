package main

import (
	"fmt"
	"reflect"
	"strconv"
)

func main() {
	s := "1101"
	fmt.Println("s is", reflect.TypeOf(s), s)

	i, err := strconv.ParseInt(s, 2, 0)
	if err != nil {
		panic(err)
	}

	fmt.Println("i is", reflect.TypeOf(i), i)
}
