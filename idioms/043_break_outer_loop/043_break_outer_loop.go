package main

import "fmt"
import "os"

var m = [][]int{
	{1, 2, 3},
	{11, 0, 30},
	{5, -20, 55},
	{0, 0, -60},
}

func main() {
mainloop:
	for i, line := range m {
		fmt.Fprintln(os.Stderr, "Searching in line", i)
		for _, v := range line {
			if v < 0 {
				fmt.Println("Found ", v)
				break mainloop
			}
		}
	}

	fmt.Println("Done.")
}
