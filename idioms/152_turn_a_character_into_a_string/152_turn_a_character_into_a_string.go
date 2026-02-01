package main

import (
	"fmt"
	"os"
)

func main() {
	var c rune = os.PathSeparator
	fmt.Printf("%c \n", c)

	s := fmt.Sprintf("%c", c)
	fmt.Printf("%#v \n", s)
}
