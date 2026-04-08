package main

import "fmt"
import "io/ioutil"
import "encoding/json"

func readJSONFile() error {
	var x Person

	buffer, err := ioutil.ReadFile(filename)
	if err != nil {
		return err
	}
	err = json.Unmarshal(buffer, &x)
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
