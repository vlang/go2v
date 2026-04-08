package main

import "fmt"

func main() {
	s := "Привет"
	t := string([]rune(s)[:5])
	
	fmt.Println(t)
}
