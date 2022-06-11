package main

import "fmt"

func main() {
	a := `="`        // "`=\"`"
	b := "="         // "\"=\""
	c := "\n\\"      // "\"\\n\\\\\""
	d := `\n\\`      // "`\\n\\\\`"
	e := "''"        // "\"''\""
	f := `''`        // "`''`"
	g := `\`         // "`\\`"
	h := `a"\">`     // "`a\"\\\">`"
	i := 'a'         // "'a'"
	j := '\\'        // "'\\\\'"
	k := '\''        // "'\\''"
	l := '`'         // "'`'"
	m := l           // "l"
	n := "\""        // "\"\\\"\""
	o := "\\\""      // "\"\\\\\\\"\""
	p := "Hello, 世界" // "\"Hello, 世界\""

	fmt.Println("a", a)
	fmt.Println("b", b)
	fmt.Println("c", c)
	fmt.Println("d", d)
	fmt.Println("e", e)
	fmt.Println("f", f)
	fmt.Println("g", g)
	fmt.Println("h", h)
	fmt.Println("i", i)
	fmt.Println("j", j)
	fmt.Println("k", k)
	fmt.Println("l", l)
	fmt.Println("m", m)
	fmt.Println("n", n)
	fmt.Println("o", o)
	fmt.Println("p", p)
}
