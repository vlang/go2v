package main

import (
	"fmt"
)

func main() {
	defer func() {
		if x := recover(); x != nil {
			switch e := x.(type) {
			case error:
				fmt.Println(e)
			default:
				fmt.Println(e)
			}
		}
	}()
}
