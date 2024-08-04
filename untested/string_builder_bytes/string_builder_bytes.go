package main

import "bytes"

func main() {
	buf := &bytes.Buffer{}
	test := "mytest"
	buf.WriteString(test)
	buf.Cap()
	buf.Grow(10)
	buf.Len()
	buf.String()
	buf.Reset()
}
