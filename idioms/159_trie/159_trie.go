package main

import (
	"fmt"
	"unicode/utf8"
)

type Trie struct {
	c        rune
	children map[rune]*Trie
	isLeaf   bool
	value    V
}

type V int

func main() {
	t := NewTrie(0)
	for s, v := range map[string]V{
		"to":  7,
		"tea": 3,
		"ted": 4,
		"ten": 12,
		"A":   15,
		"i":   11,
		"in":  5,
		"inn": 9,
	} {
		t.insert(s, v)
	}
	fmt.Println(t.startsWith("te", ""))
}

func NewTrie(c rune) *Trie {
	t := new(Trie)
	t.c = c
	t.children = map[rune]*Trie{}
	return t
}

func (t *Trie) insert(s string, value V) {
	if s == "" {
		t.isLeaf = true
		t.value = value
		return
	}
	c, tail := cut(s)
	child, exists := t.children[c]
	if !exists {
		child = NewTrie(c)
		t.children[c] = child
	}
	child.insert(tail, value)
}

func (t *Trie) startsWith(p string, accu string) []string {
	if t == nil {
		return nil
	}
	if p == "" {
		var result []string
		if t.isLeaf {
			result = append(result, accu)
		}
		for c, child := range t.children {
			rec := child.startsWith("", accu+string(c))
			result = append(result, rec...)
		}
		return result
	}
	c, tail := cut(p)
	return t.children[c].startsWith(tail, accu+string(c))
}

func cut(s string) (head rune, tail string) {
	r, size := utf8.DecodeRuneInString(s)
	return r, s[size:]
}