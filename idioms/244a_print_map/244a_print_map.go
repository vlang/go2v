package main

import (
	"fmt"
)

func main() {
	{
		m := map[string]int{
			"eleven":     11,
			"twenty-two": 22,
		}
		fmt.Println(m)
	}

	{
		x, y := 7, 8
		m := map[string]*int{
			"seven": &x,
			"eight": &y,
		}
		fmt.Println(m)
	}
}
