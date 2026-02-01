package main

import (
	"fmt"
	"time"
)

type Company string

type Employee struct {
	FirstName string
	LastName  string
}

func (e *Employee) String() string {
	return "<" + e.FirstName + " " + e.LastName + ">"
}

type Payroll struct {
	Company   Company
	Boss      *Employee
	Employee  *Employee
	StartDate time.Time
	EndDate   time.Time
	Amount    int
}

// Creates a blank payroll for a specific employee with specific boss in specific company
type PayFactory func(Company, *Employee, *Employee) Payroll

// Creates a blank payroll for a specific employee
type CustomPayFactory func(*Employee) Payroll

func CurryPayFactory(pf PayFactory, company Company, boss *Employee) CustomPayFactory {
	return func(e *Employee) Payroll {
		return pf(company, boss, e)
	}
}

func NewPay(company Company, boss *Employee, employee *Employee) Payroll {
	return Payroll{
		Company:  company,
		Boss:     boss,
		Employee: employee,
	}
}

func main() {
	me := Employee{"Jack", "Power"}

	// I happen to be head of the HR department of Richissim Inc.
	var myLittlePayFactory CustomPayFactory = CurryPayFactory(NewPay, "Richissim", &me)

	fmt.Println(myLittlePayFactory(&Employee{"Jean", "Dupont"}))
	fmt.Println(myLittlePayFactory(&Employee{"Antoine", "Pol"}))
}
