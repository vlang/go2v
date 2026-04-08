package main

import (
	"fmt"
	"io/ioutil"
	"log"
)

func main() {
	d := "/"

	x, err := ioutil.ReadDir(d)
	if err != nil {
		log.Fatal(err)
	}

	for _, f := range x {
		fmt.Println(f.Name())
	}
}
