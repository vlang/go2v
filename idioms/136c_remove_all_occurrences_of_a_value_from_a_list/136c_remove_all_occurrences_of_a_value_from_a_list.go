package main

import (
	"fmt"
	"runtime"
)

func main() {
	var items []*image
	{
		red := newUniform(rgb{0xFF, 0, 0})
		white := newUniform(rgb{0xFF, 0xFF, 0xFF})
		items = []*image{red, white, red} // Like the flag of Austria
		fmt.Println("items =", items)

		x := red
		j := 0
		for i, v := range items {
			if v != x {
				items[j] = items[i]
				j++
			}
		}
		for k := j; k < len(items); k++ {
			items[k] = nil
		}
		items = items[:j]
	}

	// At this point, red can be garbage collected

	printAllocInfo()

	fmt.Println("items =", items) // Not the original flag anymore...
	fmt.Println("items undelying =", items[:3])
}

type image [1024][1024]rgb
type rgb [3]byte

func newUniform(color rgb) *image {
	im := new(image)
	for x := range im {
		for y := range im[x] {
			im[x][y] = color
		}
	}
	return im
}

func printAllocInfo() {
	var stats runtime.MemStats
	runtime.GC()
	runtime.ReadMemStats(&stats)
	fmt.Println("Bytes allocated (total):", stats.TotalAlloc)
	fmt.Println("Bytes still allocated:  ", stats.Alloc)
}
