package main

import (
	"fmt"
	"math/rand"
)

type T string

func pickT(x []T) T {
	return x[rand.Intn(len(x))]
}

func main() {
	var list = []T{"bleen", "fuligin", "garrow", "grue", "hooloovoo"}
	fmt.Println(pickT(list))
}