package main

import "fmt"

func (start *Vertex) Bfs(f func(*Vertex)) {
	queue := []*Vertex{start}
	seen := map[*Vertex]bool{start: true}
	for len(queue) > 0 {
		v := queue[0]
		queue = queue[1:]
		f(v)
		for next, isEdge := range v.Neighbours {
			if isEdge && !seen[next] {
				queue = append(queue, next)
				seen[next] = true
			}
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

	london.Bfs(VertexPrint)
}
