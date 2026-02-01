package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
)

func main() {
	{
		p := "/usr"

		dir, err := os.Open(p)
		if err != nil {
			panic(err)
		}
		defer dir.Close()
		_, err = dir.Readdirnames(1)
		b := err == io.EOF
		fmt.Println(p, "is empty:", b)
	}
	{
		p := "/tmp"

		dir, err := os.Open(p)
		if err != nil {
			panic(err)
		}
		defer dir.Close()
		_, err = dir.Readdirnames(1)
		b := err == io.EOF
		fmt.Println(p, "is empty:", b)
	}
	{
		p, err := ioutil.TempDir("", "")
		if err != nil {
			panic(err)
		}

		dir, err := os.Open(p)
		if err != nil {
			panic(err)
		}
		defer dir.Close()
		_, err = dir.Readdirnames(1)
		b := err == io.EOF
		fmt.Println(p, "is empty:", b)
	}
	{
		p := "/tmp"

		dir, err := os.Open(p)
		if err != nil {
			panic(err)
		}
		defer dir.Close()
		_, err = dir.Readdirnames(1)
		b := err == io.EOF
		fmt.Println(p, "is empty:", b)
	}
}
