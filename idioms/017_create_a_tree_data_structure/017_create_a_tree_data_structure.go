package main

import "fmt"

type Tree struct {
	Key      key
	Deco     value
	Children []*Tree
}

type key string
type value string

func (t *Tree) String() string {
	str := "("
	str += string(t.Deco)
	if len(t.Children) == 0 {
		return str + ")"
	}
	str += " ("
	for _, child := range t.Children {
		str += child.String()
	}
	str += "))"
	return str
}

func (this *Tree) AddChild(x key, v value) *Tree {
	child := &Tree{Key: x, Deco: v}
	this.Children = append(this.Children, child)
	return child
}

func main() {
	tree := &Tree{Key: "Granpa", Deco: "Abraham"}
	subtree := tree.AddChild("Dad", "Homer")
	subtree.AddChild("Kid 1", "Bart")
	subtree.AddChild("Kid 2", "Lisa")
	subtree.AddChild("Kid 3", "Maggie")

	fmt.Println(tree)
}
