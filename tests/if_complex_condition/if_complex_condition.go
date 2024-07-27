package main

import "fmt"

func main() {
	if true {
	}
	if 3 < 4 {
	}
	if 3 != 4 {
	}
	if 3 == 4 {
	}
	if 3 <= 4 {
	}
	if 3 <= 4 && true {
	}
	if (3 <= 4 && true) || false {
	}

	var c byte = 'X'
	if !(c == '(' || c == 'B' || c == 'C' || c == 'D' || c == 'F' ||
		c == 'I' || c == 'J' || c == 'L' || c == 'S' || c == 'Z' ||
		c == '[') {
		fmt.Println("Invalid")
	}
}
