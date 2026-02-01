package main

import "fmt"
import "strconv"

func main() {
	x := int64(13)
	s := strconv.FormatInt(x, 2)

	fmt.Println(s)
}
