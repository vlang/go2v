package main

import (
	"fmt"
	"regexp"
	"strings"
	"time"
)

func clock(f func()) time.Duration {
	t := time.Now()
	f()
	return time.Since(t)
}

func f() {
	re := regexp.MustCompilePOSIX("|A+{300}")
	re.FindAllString(strings.Repeat("A", 299), -1)
}

func main() {
	d := clock(f)

	// The result is always zero in the playground, which has a fixed clock!
	// Try it on your workstation instead.
	fmt.Println(d)
}
