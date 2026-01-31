package main

import "fmt"

func Reverse(s string) string {
	runes := []rune(s)
	for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
		runes[i], runes[j] = runes[j], runes[i]
	}
	return string(runes)
}

func main() {
	input := "The quick brown 狐 jumped over the lazy 犬"
	fmt.Println(Reverse(input))
	// Original string unaltered
	fmt.Println(input)
}
