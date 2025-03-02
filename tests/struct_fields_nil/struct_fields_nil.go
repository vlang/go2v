package main

type Node struct {
	Parent, FirstChild, LastChild, PrevSibling, NextSibling *Node

	Type      string
	DataAtom  int
	Data      string
	Namespace string
	Attr      []Node
}
