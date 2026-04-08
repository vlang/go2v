package main

import (
	"fmt"
	"io/ioutil"
	"os"
)

func main() {
	fp := "foo.txt"
	_, err := os.Stat(fp)
	b := !os.IsNotExist(err)
	fmt.Println(fp, "exists:", b)

	fp = "bar.txt"
	_, err = os.Stat(fp)
	b = !os.IsNotExist(err)
	fmt.Println(fp, "exists:", b)
}

func init() {
	ioutil.WriteFile("foo.txt", []byte(`abc`), 0644)
}
