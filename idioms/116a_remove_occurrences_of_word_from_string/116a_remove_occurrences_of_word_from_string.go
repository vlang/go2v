package main

import "fmt"
import "strings"

func main() {
	s1 := "foobarfoo"
	w := "foo"
	
	s2 := strings.Replace(s1, w, "", -1)
	
	fmt.Println(s2)
}