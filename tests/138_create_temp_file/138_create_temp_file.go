package main

import (
	"io/ioutil"
	"log"
	"os"
)

func main() {
	content := []byte("Big bag of misc data")

	log.Println("Opening new temp file")
	tmpfile, err := ioutil.TempFile("", "example")
	if err != nil {
		log.Fatal(err)
	}
	tmpfilename := tmpfile.Name()
	defer os.Remove(tmpfilename) // clean up
	log.Println("Opened new file", tmpfilename)

	log.Println("Writing [[", string(content), "]]")
	if _, err := tmpfile.Write(content); err != nil {
		log.Fatal(err)
	}
	if err := tmpfile.Close(); err != nil {
		log.Fatal(err)
	}
	log.Println("Closed", tmpfilename)

	log.Println("Opening", tmpfilename)
	buffer, err := ioutil.ReadFile(tmpfilename)
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Read[[", string(buffer), "]]")
}
