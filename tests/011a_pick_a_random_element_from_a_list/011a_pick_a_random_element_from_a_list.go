package main

import (
	"fmt"
	"math/rand"
)

var x = []string{"bleen", "fuligin", "garrow", "grue", "hooloovoo"}

func main() {
	fmt.Println(x[rand.Intn(len(x))])
}
