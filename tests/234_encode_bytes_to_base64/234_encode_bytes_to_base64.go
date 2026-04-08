package main

import (
	"encoding/base64"
	"fmt"
)

func main() {
	data := []byte("Hello world")
	s := base64.StdEncoding.EncodeToString(data)
	fmt.Println(s)
}
