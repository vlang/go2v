package main

import "fmt"

func main() {
	name := "V"
	count := 7
	formatted := fmt.Sprintf("name=%q count=%02d type=%T hex=%X %%", name, count, count, count)
	fmt.Printf("-> %s", formatted)
	err := fmt.Errorf("bad %q", name)
	fmt.Println(err)
}

