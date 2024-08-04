package main

type EnumFieldTest int

const (
	EnumFieidZero EnumFieldTest = iota
	EnumFieldFive               = 5
	EnumFieldSix                = iota
)

var DefaultMsgAcceptFunc = defaultMsgAcceptFunc

const MsgAccept msgAcceptAction = iota

func defaultMsgAcceptFunc() {
	return MsgAccept
}
