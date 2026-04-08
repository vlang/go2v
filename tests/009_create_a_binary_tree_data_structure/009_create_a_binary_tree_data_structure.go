package main

import "fmt"

type BinTree struct {
	Value int
	Left  *BinTree
	Right *BinTree
}

func inorder(root *BinTree) {
	if root == nil {
		return
	}

	inorder(root.Left)
	fmt.Printf("%d ", root.Value)
	inorder(root.Right)
}

func main() {
	root := &BinTree{1, nil, nil}
	root.Left = &BinTree{2, nil, nil}
	root.Right = &BinTree{3, nil, nil}
	root.Left.Left = &BinTree{4, nil, nil}
	root.Left.Right = &BinTree{5, nil, nil}
	root.Right.Right = &BinTree{6, nil, nil}
	root.Left.Left.Left = &BinTree{7, nil, nil}

	inorder(root)
}
