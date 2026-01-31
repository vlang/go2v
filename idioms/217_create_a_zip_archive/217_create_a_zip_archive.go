package main

import (
	"archive/zip"
	"bytes"
	"io"
	"io/ioutil"
	"log"
	"os"
)

func main() {
	list := []string{
		"readme.txt",
		"gopher.txt",
		"todo.txt",
	}
	name := "archive.zip"

	err := makeZip(list, name)
	if err != nil {
		log.Fatal(err)
	}
}

func makeZip(list []string, name string) error {
	// Create a buffer to write our archive to.
	buf := new(bytes.Buffer)

	// Create a new zip archive.
	w := zip.NewWriter(buf)

	// Add some files to the archive.
	for _, filename := range list {
		// Open file for reading
		input, err := os.Open(filename)
		if err != nil {
			return err
		}
		// Create ZIP entry for writing
		output, err := w.Create(filename)
		if err != nil {
			return err
		}

		_, err = io.Copy(output, input)
		if err != nil {
			return err
		}
	}

	// Make sure to check the error on Close.
	err := w.Close()
	if err != nil {
		return err
	}

	N := buf.Len()
	err = ioutil.WriteFile(name, buf.Bytes(), 0777)
	if err != nil {
		return err
	}
	log.Println("Written a ZIP file of", N, "bytes")

	return nil
}

func init() {
	// Create some files in the filesystem.
	var files = []struct {
		Name, Body string
	}{
		{"readme.txt", "This archive contains some text files."},
		{"gopher.txt", "Gopher names:\nGeorge\nGeoffrey\nGonzo"},
		{"todo.txt", "Get animal handling licence.\nWrite more examples."},
	}
	for _, file := range files {
		err := ioutil.WriteFile(file.Name, []byte(file.Body), 0777)
		if err != nil {
			log.Fatal(err)
		}
	}
}
