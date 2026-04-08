package main

import "fmt"

func main() {
	s := "hello, world! 문자"
	t := string([]rune(s)[len([]rune(s))-5:])
	fmt.Println(t)
}
