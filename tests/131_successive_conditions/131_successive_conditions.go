package main

import (
	"fmt"
	"strings"
)

func conditional(x string) {
	switch {
	case c1(x):
		f1()
	case c2(x):
		f2()
	case c3(x):
		f3()
	}
}

func main() {
	conditional("dog Snoopy")
	conditional("fruit Raspberry")
}

func f1() {
	fmt.Println("I'm a Human")
}

func f2() {
	fmt.Println("I'm a Dog")
}

func f3() {
	fmt.Println("I'm a Fruit")
}

var c1, c2, c3 = prefixCheck("human"), prefixCheck("dog"), prefixCheck("fruit")

func prefixCheck(prefix string) func(string) bool {
	return func(x string) bool {
		return strings.HasPrefix(x, prefix)
	}
}
