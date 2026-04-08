package main

import "fmt"

func main() {
	s := "Résumé"

	i := 0
	for _, c := range s {
		fmt.Printf("Char %d is %c\n", i, c)
		i++
	}
}
