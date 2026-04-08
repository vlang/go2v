package main

import (
	"fmt"
	"os"
)

func main() {
	path := "foo/bar"
	_, err := os.Stat(path)
	b := !os.IsNotExist(err)
	fmt.Println(path, "exists:", b)

	err = os.Mkdir(path, os.ModeDir)
	if err != nil {
		fmt.Println("Could not create", path, "with os.Mkdir")
	}

	info, err2 := os.Stat(path)
	b = !os.IsNotExist(err2)
	fmt.Println(path, "exists:", b)

	err = os.MkdirAll(path, os.ModeDir)
	if err != nil {
		fmt.Println("Could not create", path, "with os.MkdirAll")
	}

	info, err2 = os.Stat(path)
	b = !os.IsNotExist(err2)
	fmt.Println(path, "exists:", b)
	fmt.Println(path, "is a directory:", info.IsDir())
}
