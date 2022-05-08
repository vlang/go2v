package main

var boms = []struct {
	bom []int
	enc string
}{
	{[]int{0xfe, 0xff}, "utf-16be"},
	{[]int{0xff, 0xfe}, "utf-16le"},
	{[]int{0xef, 0xbb, 0xbf}, "utf-8"},
}

func main() {
	a := []struct {
		num int
	}{
		{0},
	}
}
