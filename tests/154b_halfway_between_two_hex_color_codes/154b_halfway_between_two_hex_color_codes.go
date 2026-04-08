package main

import (
	"fmt"
	"strconv"
	"strings"
)

// For concision, halfway assume valid inputs.
// Caller must have explicitly checked that c1, c2 are well-formed color codes.
func halfway(c1, c2 string) string {
	var buf [7]byte
	buf[0] = '#'
	for i := 0; i < 3; i++ {
		sub1 := c1[1+2*i : 3+2*i]
		sub2 := c2[1+2*i : 3+2*i]
		v1, _ := strconv.ParseInt(sub1, 16, 0)
		v2, _ := strconv.ParseInt(sub2, 16, 0)
		v := (v1 + v2) / 2
		sub := fmt.Sprintf("%02X", v)
		copy(buf[1+2*i:3+2*i], sub)
	}
	c := string(buf[:])

	return c
}

func main() {
	c1 := "#15293E"
	c2 := "#012549"

	if err := checkFormat(c1); err != nil {
		panic(fmt.Errorf("Wrong input %q: %v", c1, err))
	}
	if err := checkFormat(c2); err != nil {
		panic(fmt.Errorf("Wrong input %q: %v", c2, err))
	}

	c := halfway(c1, c2)
	fmt.Println("The average of", c1, "and", c2, "is", c)
}

func checkFormat(color string) error {
	if len(color) != 7 {
		return fmt.Errorf("Hex colors have exactly 7 chars")
	}
	if color[0] != '#' {
		return fmt.Errorf("Hex colors start with #")
	}
	isNotDigit := func(c rune) bool { return (c < '0' || c > '9') && (c < 'a' || c > 'f') }
	if strings.IndexFunc(strings.ToLower(color[1:]), isNotDigit) != -1 {
		return fmt.Errorf("Forbidden char")
	}
	return nil
}
