package main

func main() {
first:
	for i := 0; i < 10; i++ {
		for j := 0; j < 10; j++ {
			if j == 5 {
				continue first
			}
			if j > 7 {
				break
			}
		}
	}
}
