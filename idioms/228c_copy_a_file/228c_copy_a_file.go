package main

import (
	"fmt"
	"io"
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
	f, err := os.Open(src)
	if err != nil {
		return err
	}
	defer f.Close()
	stat, err := f.Stat()
	if err != nil {
		return err
	}
	g, err := os.OpenFile(dst, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, stat.Mode())
	if err != nil {
		return err
	}
	defer g.Close()
	_, err = io.Copy(g, f)
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
