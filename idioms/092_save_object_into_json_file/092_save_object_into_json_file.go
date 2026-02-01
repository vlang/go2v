package main

import "fmt"
import "io/ioutil"
import "encoding/json"

func writeJSONFile() error {
	x := Person{
		FirstName: "Napoléon",
		Age:       51,
	}

	buffer, err := json.MarshalIndent(x, "", "  ")
	if err != nil {
		return err
	}
	return ioutil.WriteFile(filename, buffer, 0644)
}

func main() {
	err := writeJSONFile()
	if err != nil {
		panic(err)
	}
	fmt.Println("Done.")
}

type Person struct {
	FirstName string
	Age       int
}

const filename = "/tmp/data.json"
