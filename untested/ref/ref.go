package main

import "crypto/aes"

type BinTree struct {
	Value string
	Left  *BinTree
	Right *BinTree
	List  []*BinTree
	Exter []*aes.KeySizeError
}
