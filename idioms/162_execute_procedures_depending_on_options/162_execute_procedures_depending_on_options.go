package main

import (
	"flag"
	"fmt"
	"os"
)

func init() {
	// Just for testing in the Playground, let's simulate
	// the user called this program with command line
	// flags -f and -b
	os.Args = []string{"program", "-f", "-b"}
}

var b = flag.Bool("b", false, "Do bat")
var f = flag.Bool("f", false, "Do fox")

func main() {
	flag.Parse()
	if *b {
		bar()
	}
	if *f {
		fox()
	}
	fmt.Println("The end.")
}

func bar() {
	fmt.Println("BAR")
}

func fox() {
	fmt.Println("FOX")
}
