// You can edit this code!
// Click here and start typing.
package main

import (
	"fmt"
	"math"
)

func addingWillOverflow(x int, y int) bool {
	if x > 0 {
		return y > math.MaxInt-x
	}
	return y < math.MinInt-x
}

func main() {
	fmt.Println(addingWillOverflow(math.MaxInt, math.MaxInt))
	fmt.Println(addingWillOverflow(math.MaxInt, math.MinInt))
	fmt.Println(addingWillOverflow(math.MinInt, math.MinInt))
	fmt.Println(addingWillOverflow(0, 0))
	fmt.Println(addingWillOverflow(0, math.MaxInt))
	fmt.Println(addingWillOverflow(0, math.MinInt))
}
