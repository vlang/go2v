package main

import "fmt"

func main() {
	s := "hello, utf-8 문자들"
	i, j := 7, 15
	
	t := string([]rune(s)[i:j])
	
	fmt.Println(t)
}
