package main

type Ok struct {
	a int
	b string
}

func main() {
	long := Ok{
		a: 1,
		b: "hello",
	}
	short := Ok{3, "hello"}
}
