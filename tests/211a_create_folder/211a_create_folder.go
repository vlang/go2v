package main

import (
	"fmt"
	"os"
)

func main() {
	path := "foo"
	_, err := os.Stat(path)
	b := !os.IsNotExist(err)
	fmt.Println(path, "exists:", b)

	err = os.Mkdir(path, os.ModeDir)
	if err != nil {
		panic(err)
	}

	info, err2 := os.Stat(path)
	b = !os.IsNotExist(err2)
	fmt.Println(path, "exists:", b)
	fmt.Println(path, "is a directory:", info.IsDir())
}
