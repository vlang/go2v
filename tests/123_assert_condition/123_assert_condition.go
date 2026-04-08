package main

import "fmt"

//
// The code may look fine, but
// obviously we have a bug.
//

func main() {
	salary = 65000
	employees = 120000
	totalPayroll = salary * employees

	if !isConsistent() {
		panic("State consistency violated")
	}
	fmt.Println("Everything fine")
}

var salary int32
var employees int32
var totalPayroll int32

func isConsistent() bool {
	return salary >= 0 &&
		employees >= 0 &&
		totalPayroll >= 0
}
