package main

import (
	"fmt"
)

func main() {
	{
		a := []int{11, 22, 33}
		fmt.Println(a)
	}

	{
		a := []string{"aa", "bb"}
		fmt.Println(a)
	}

	{
		type Person struct {
			First string
			Last  string
		}
		x := Person{
			First: "Jane",
			Last:  "Doe",
		}
		y := Person{
			First: "John",
			Last:  "Doe",
		}
		a := []Person{x, y}
		fmt.Println(a)
	}

	{
		x, y := 11, 22
		a := []*int{&x, &y}
		fmt.Println(a)
	}
}