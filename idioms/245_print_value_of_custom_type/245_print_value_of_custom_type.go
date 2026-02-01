package main

import (
	"fmt"
)

// T represents a tank. It doesn't implement fmt.Stringer.
type T struct {
	name      string
	weight    int
	firePower int
}

// Person implement fmt.Stringer.
type Person struct {
	FirstName   string
	LastName    string
	YearOfBirth int
}

func (p Person) String() string {
	return fmt.Sprintf("%s %s, born %d", p.FirstName, p.LastName, p.YearOfBirth)
}

func main() {
	{
		x := T{
			name:      "myTank",
			weight:    100,
			firePower: 90,
		}

		fmt.Println(x)
	}
	{
		x := Person{
			FirstName:   "John",
			LastName:    "Doe",
			YearOfBirth: 1958,
		}

		fmt.Println(x)
	}
}