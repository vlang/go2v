package enum

import (
	"fmt"
	"io"
)

type EnumTest int

const (
	EnumTestZero EnumTest = iota
	EnumTestOne
	EnumTestTwo
	EnumTestThree
)

type EnumFieldTest int

const (
	EnumFieidZero EnumFieldTest = iota
	EnumFieldFive = 5
	EnumFieldSix = iota
)