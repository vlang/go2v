package main

import (
	"fmt"
	"os"
)

func main() {
	path := "foo"
	info, err := os.Stat(path)
	b := !os.IsNotExist(err) && info.IsDir()
	fmt.Println(path, "is a directory:", b)

	err = os.Mkdir(path, os.ModeDir)
	if err != nil {
		panic(err)
	}

	info, err = os.Stat(path)
	b = !os.IsNotExist(err) && info.IsDir()
	fmt.Println(path, "is a directory:", b)
}
