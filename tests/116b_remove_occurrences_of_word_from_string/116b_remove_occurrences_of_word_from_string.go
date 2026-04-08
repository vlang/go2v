package main

import "fmt"
import "strings"

func main() {
	s1 := "foobarfoo"
	w := "foo"
	
	s2 := strings.ReplaceAll(s1, w, "")
	
	fmt.Println(s2)
}