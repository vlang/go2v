package main

import "fmt"

func (v *Vertex) Dfs(f func(*Vertex), seen map[*Vertex]bool) {
	seen[v] = true
	f(v)
	for next, isEdge := range v.Neighbours {
		if isEdge && !seen[next] {
			next.Dfs(f, seen)
		}
	}
}

type Vertex struct {
	Id         int
	Label      string
	Neighbours map[*Vertex]bool
}

type Graph []*Vertex

func NewVertex(id int, label string) *Vertex {
	return &Vertex{
		Id:         id,
		Label:      label,
		Neighbours: make(map[*Vertex]bool),
	}
}

func (v *Vertex) AddNeighbour(w *Vertex) {
	v.Neighbours[w] = true
}

func VertexPrint(v *Vertex) {
	fmt.Printf("%v (%v)\n", v.Id, v.Label)
}

func main() {
	// Some cities
	london := NewVertex(0, "London")
	ny := NewVertex(1, "New York City")
	berlin := NewVertex(2, "Berlin")
	paris := NewVertex(3, "Paris")
	tokyo := NewVertex(4, "Tokyo")

	g := Graph{
		london,
		ny,
		berlin,
		paris,
		tokyo,
	}
	_ = g

	london.AddNeighbour(paris)
	london.AddNeighbour(ny)
	ny.AddNeighbour(london)
	ny.AddNeighbour(paris)
	ny.AddNeighbour(tokyo)
	tokyo.AddNeighbour(paris)
	paris.AddNeighbour(tokyo)
	paris.AddNeighbour(berlin)

	alreadySeen := map[*Vertex]bool{}
	london.Dfs(VertexPrint, alreadySeen)
}
