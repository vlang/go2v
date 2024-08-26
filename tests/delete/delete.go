package main

type MyStruct struct {
	msm map[string]int
}

func main() {
	m := map[string]float64{
		"pi": 3.14,
		"f":  1.0,
	}
	delete(m, "pi")

	key := "f"
	delete(m, key)

	ms := MyStruct{msm: map[string]int{"1": 1}}
	delete(ms.msm, "1")
}
