package main

import (
	"fmt"
	"regexp"
)

func main() {
	r := regexp.MustCompile("htt+p")

	for _, s := range []string{
		"hp",
		"htp",
		"http",
		"htttp",
		"httttp",
		"htttttp",
		"htttttp",
		"word htttp in a sentence",
	} {
		fmt.Println(s, "=>", r.MatchString(s))
	}
}
