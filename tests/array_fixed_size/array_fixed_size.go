package main

type Ok struct{}

func main() {
	full := [4]int{
		4, 5, 23, 55,
	}

	missing := [6]string{
		"John",
		"Paul",
		"George",
		"Ringo",
	}

	missing_struct := [2]Ok{
		Ok{},
	}

	missing_empty := [2]int{}
}
