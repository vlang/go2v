package main

import (
	"bufio"
	"fmt"
	"log"
	"strconv"
	"strings"
)

func main() {
	var ints []int
	s := bufio.NewScanner(osStdin)
	s.Split(bufio.ScanWords)
	for s.Scan() {
		i, err := strconv.Atoi(s.Text())
		if err == nil {
			ints = append(ints, i)
		}
	}
	if err := s.Err(); err != nil {
		log.Fatal(err)
	}
	fmt.Println(ints)
}

// osStdin simulates os.Stdin
var osStdin = strings.NewReader(`
11
22
33  `)
