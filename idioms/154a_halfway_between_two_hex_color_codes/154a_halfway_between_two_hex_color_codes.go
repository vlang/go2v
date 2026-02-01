package main

import (
	"fmt"
	"strconv"
	"strings"
)

// For concision, halfway assume valid inputs.
// Caller must have explicitly checked that c1, c2 are well-formed color codes.
func halfway(c1, c2 string) string {
	r1, _ := strconv.ParseInt(c1[1:3], 16, 0)
	r2, _ := strconv.ParseInt(c2[1:3], 16, 0)
	r := (r1 + r2) / 2

	g1, _ := strconv.ParseInt(c1[3:5], 16, 0)
	g2, _ := strconv.ParseInt(c2[3:5], 16, 0)
	g := (g1 + g2) / 2

	b1, _ := strconv.ParseInt(c1[5:7], 16, 0)
	b2, _ := strconv.ParseInt(c2[5:7], 16, 0)
	b := (b1 + b2) / 2

	c := fmt.Sprintf("#%02X%02X%02X", r, g, b)
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
