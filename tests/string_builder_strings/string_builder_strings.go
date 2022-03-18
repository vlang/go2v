package main

import "strings"

func main() {
	buf := &strings.Builder{}
	test := "mytest"
	buf.WriteString(test)
	buf.Cap()
	buf.Grow(10)
	buf.Len()
	buf.String()
	buf.Reset()
}
