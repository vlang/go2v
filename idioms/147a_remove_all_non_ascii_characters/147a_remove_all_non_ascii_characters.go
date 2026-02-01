package main

import (
	"fmt"
	"regexp"
)

func main() {
	s := "dæmi : пример : příklad : thí dụ"

	re := regexp.MustCompile("[[:^ascii:]]")
	t := re.ReplaceAllLiteralString(s, "")

	fmt.Println(t)
}
