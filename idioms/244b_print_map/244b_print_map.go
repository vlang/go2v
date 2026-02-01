package main

import (
	"fmt"
)

func main() {
	m := map[string]string{
		"eleven":     "onze",
		"twenty-two": "vingt-deux",
	}

	fmt.Printf("%q", m)
}
