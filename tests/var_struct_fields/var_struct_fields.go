package main

type Ok struct {
	a int
	b string
	m map[string]int
}

func main() {
	long := Ok{
		a: 1,
		b: "hello",
	}
	short := Ok{3, "hello"}
}
