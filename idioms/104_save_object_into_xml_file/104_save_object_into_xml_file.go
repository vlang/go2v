package main

import "encoding/xml"
import "io/ioutil"
import "fmt"

func writeXMLFile() error {
	x := Person{
		FirstName: "Napoléon",
		Age:       51,
	}

	buffer, err := xml.MarshalIndent(x, "", "  ")
	if err != nil {
		return err
	}
	return ioutil.WriteFile(filename, buffer, 0644)
}

func main() {
	err := writeXMLFile()
	if err != nil {
		panic(err)
	}
	fmt.Println("Done.")

	readBackBuffer, err := ioutil.ReadFile(filename)
	if err != nil {
		panic(err)
	}
	readBack := string(readBackBuffer)
	fmt.Println("File", filename, "now contains:")
	fmt.Println(readBack)
}

type Person struct {
	FirstName string
	Age       int
}

const filename = "/tmp/data.xml"
