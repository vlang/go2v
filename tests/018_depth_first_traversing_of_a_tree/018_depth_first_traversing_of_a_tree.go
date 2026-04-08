package main

import . "fmt"

func (t *Tree) Dfs(f func(*Tree)) {
	if t == nil {
		return
	}
	f(t)
	for _, child := range t.Children {
		child.Dfs(f)
	}
}

type key string
type value string

type Tree struct {
	Key      key
	Deco     value
	Children []*Tree
}

func (this *Tree) AddChild(x key, v value) {
	child := &Tree{Key: x, Deco: v}
	this.Children = append(this.Children, child)
}

func NodePrint(node *Tree) {
	Printf("%v (%v)\n", node.Deco, node.Key)
}

func main() {
	tree := &Tree{Key: "Granpa", Deco: "Abraham"}
	tree.AddChild("Dad", "Homer")
	tree.Children[0].AddChild("Kid 1", "Bart")
	tree.Children[0].AddChild("Kid 2", "Lisa")
	tree.Children[0].AddChild("Kid 3", "Maggie")

	tree.Dfs(NodePrint)
}
