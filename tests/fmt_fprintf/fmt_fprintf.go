package main

import (
	"fmt"
	"os"
)

func main() {
	value := 42
	_ = fmt.Fprintf(os.Stderr, "value=%d", value)
	_ = fmt.Fprintln(os.Stdout, "done", value)
	_ = fmt.Fprint(os.Stdout, "tail", value)
}

