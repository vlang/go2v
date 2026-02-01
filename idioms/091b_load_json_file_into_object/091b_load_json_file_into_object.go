package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

func readJSONFile() error {
	var x Person

	r, err := os.Open(filename)
	if err != nil {
		return err
	}
	decoder := json.NewDecoder(r)
	err = decoder.Decode(&x)
	if err != nil {
		return err
	}

	fmt.Println(x)
	return nil
}

func main() {
	err := readJSONFile()
	if err != nil {
		panic(err)
	}
}

type Person struct {
	FirstName string
	Age       int
}

const filename = "/tmp/data.json"

func init() {
	err := ioutil.WriteFile(filename, []byte(`
		{
			"FirstName":"Napoléon",
			"Age": 51 
		}`), 0644)
	if err != nil {
		panic(err)
	}
}
