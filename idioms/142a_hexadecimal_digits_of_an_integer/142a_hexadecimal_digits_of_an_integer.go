package main

import "fmt"
import "strconv"

func main() {
	x := int64(999)
	s := strconv.FormatInt(x, 16)

	fmt.Println(s)
}
