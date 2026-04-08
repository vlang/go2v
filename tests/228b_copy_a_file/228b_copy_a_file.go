package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
)

func main() {
	src, dst := "/tmp/file1", "/tmp/file2"

	err := copy(dst, src)
	if err != nil {
		log.Fatalln(err)
	}

	stat, err := os.Stat(dst)
	if err != nil {
		log.Fatalln(err)
	}
	fmt.Println(dst, "exists, it has size", stat.Size(), "and mode", stat.Mode())
}

func copy(dst, src string) error {
	data, err := ioutil.ReadFile(src)
	if err != nil {
		return err
	}
	stat, err := os.Stat(src)
	if err != nil {
		return err
	}
	err = ioutil.WriteFile(dst, data, stat.Mode())
	if err != nil {
		return err
	}
	return os.Chmod(dst, stat.Mode())
}

func init() {
	data := []byte("Hello")
	err := ioutil.WriteFile("/tmp/file1", data, 0777)
	if err != nil {
		log.Fatalln(err)
	}
	err = os.Chmod("/tmp/file1", 0777)
	if err != nil {
		log.Fatalln(err)
	}
}
