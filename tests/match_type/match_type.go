package main

func abc(s interface{}) {
	switch s.(type) {
	case int:
		println("a")
	case string:
		println("b")
	default:
		println("c")
	}
}
