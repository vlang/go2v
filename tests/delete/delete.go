package main

func main() {
	m := map[string]float64{
		"pi": 3.14,
		"f":  1.0,
	}
	delete(m, "pi")

	key := "f"
	delete(m, key)
}
