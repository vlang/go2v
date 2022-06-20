package main

import (
	"fmt"
	"os"
)

func main() {
	// Errorf
	const name, id = "bueller", 17
	err := fmt.Errorf("user %q (id %d) not found", name, id)
	fmt.Println(err.Error())

	// Fprint
	fmt.Fprint(os.Stdout, "hey")
	fmt.Fprint(os.Stderr, "hey")

	// Fprintf
	fmt.Fprintf(os.Stdout, "%s", "hey")
	fmt.Fprintf(os.Stderr, "%s", "hey")

	// Fprintln
	fmt.Fprintln(os.Stdout, "hey")
	fmt.Fprintln(os.Stderr, "hey")

	// Print
	fmt.Print("hey")

	// Printf
	fmt.Printf("%s", "hey")

	// Println
	fmt.Println("hey")

	// Sprintf
	fmt.Println(fmt.Sprintf("%s", "hey"))
}
