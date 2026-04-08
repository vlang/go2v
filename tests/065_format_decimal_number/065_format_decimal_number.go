package main

import "fmt"

func main() {
	x := 0.15625
	s := fmt.Sprintf("%.1f%%", 100.0*x)
	fmt.Println(s)
}
