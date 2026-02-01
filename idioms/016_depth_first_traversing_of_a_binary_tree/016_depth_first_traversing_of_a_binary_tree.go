package main

import . "fmt"

type key string
type value string

type BinTree struct {
	Key   key
	Deco  value
	Left  *BinTree
	Right *BinTree
}

func (bt *BinTree) Dfs(f func(*BinTree)) {
	if bt == nil {
		return
	}
	bt.Left.Dfs(f)
	f(bt)
	bt.Right.Dfs(f)
}

func main() {
	a := []key{"d", "a", "dd", "e", "h", "gg", "f", "b", "n", "v"}
	tree := &BinTree{Key: a[0]}
	for _, str := range a[1:] {
		tree.Insert(str, value(""))
	}
	tree.Dfs(NodePrint)
}

func (bt *BinTree) Insert(x key, v value) {
	if x < bt.Key {
		if bt.Left == nil {
			bt.Left = &BinTree{Key: x, Deco: v}
		} else {
			bt.Left.Insert(x, v)
		}
	} else {
		if bt.Right == nil {
			bt.Right = &BinTree{Key: x, Deco: v}
		} else {
			bt.Right.Insert(x, v)
		}
	}
}

func NodePrint(node *BinTree) {
	Println(node.Key)
}
