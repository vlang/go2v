package main

import (
	"encoding/base64"
	"fmt"
)

func main() {
	str := "SGVsbG8gd29ybGQ="

	data, err := base64.StdEncoding.DecodeString(str)
	if err != nil {
		fmt.Println("error:", err)
		return
	}

	fmt.Printf("%q\n", data)
}
