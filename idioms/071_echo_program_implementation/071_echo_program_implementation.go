package main

import "fmt"
import "os"
import "strings"

func main() {
    fmt.Println(strings.Join(os.Args[1:], " "))
}