package main

import (
	"fmt"
	"os/exec"
)

func main() {
	err := exec.Command("x", "a", "b").Run()
	fmt.Println(err)
}
