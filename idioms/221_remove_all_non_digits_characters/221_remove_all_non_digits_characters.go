package main

import (
	"fmt"
	"regexp"
)

func main() {
	s := `height="168px"`

	re := regexp.MustCompile("[^\\d]")
	t := re.ReplaceAllLiteralString(s, "")

	fmt.Println(t)
}
