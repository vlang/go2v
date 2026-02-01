package main

import "fmt"

func (root *Tree) Bfs(f func(*Tree)) {
	if root == nil {
		return
	}
	queue := []*Tree{root}
	for len(queue) > 0 {
		t := queue[0]
		queue = queue[1:]
		f(t)
		queue = append(queue, t.Children...)
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
	fmt.Printf("%v (%v)\n", node.Key, node.Deco)
}

func main() {
	tree := &Tree{Key: "World", Deco: "Our planet"}
	tree.AddChild("Europe", "A continent")
	tree.Children[0].AddChild("Germany", "A country")
	tree.Children[0].AddChild("Ireland", "A country")
	tree.Children[0].AddChild("Mediterranean Sea", "A sea")
	tree.AddChild("Asia", "A continent")
	tree.Children[0].AddChild("Japan", "A country")
	tree.Children[0].AddChild("Thailand", "A country")

	tree.Bfs(NodePrint)
}
