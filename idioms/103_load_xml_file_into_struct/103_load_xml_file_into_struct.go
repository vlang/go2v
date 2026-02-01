package main

import (
	"encoding/xml"
	"fmt"
)
import "io/ioutil"

func readXMLFile() error {
	var x Person

	buffer, err := ioutil.ReadFile(filename)
	if err != nil {
		return err
	}
	err = xml.Unmarshal(buffer, &x)
	if err != nil {
		return err
	}

	fmt.Println(x)
	return nil
}

func main() {
	err := readXMLFile()
	if err != nil {
		panic(err)
	}
}

type Person struct {
	FirstName string
	Age       int
}

const filename = "/tmp/data.xml"

func init() {
	data := `<?xml version="1.0" encoding="UTF-8"?>
		<Person>
			<FirstName>Napoléon</FirstName>
			<Age>51</Age>
		</Person>`
	err := ioutil.WriteFile(filename, []byte(data), 0644)
	if err != nil {
		panic(err)
	}
}
