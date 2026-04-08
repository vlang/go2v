package main

import "fmt"

func binarySearch(a []T, x T) int {
	imin, imax := 0, len(a)-1
	for imin <= imax {
		imid := (imin + imax) / 2
		switch {
		case a[imid] == x:
			return imid
		case a[imid] < x:
			imin = imid + 1
		default:
			imax = imid - 1
		}
	}
	return -1
}

type T int

func main() {
	a := []T{-2, -1, 0, 1, 1, 1, 6, 8, 8, 9, 10}
	for x := T(-5); x <= 15; x++ {
		i := binarySearch(a, x)
		if i == -1 {
			fmt.Println("Value", x, "not found")
		} else {
			fmt.Println("Value", x, "found at index", i)
		}
	}
}
