package main

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

func main() {
	// Schrödinger's cat possible transitions
	box := NewVertex(0, "In the box")
	dead := NewVertex(1, "Dead")
	alive := NewVertex(2, "Alive")
	g := Graph{
		box,
		dead,
		alive,
	}

	box.Neighbours[dead] = true
	box.Neighbours[alive] = true
	alive.Neighbours[dead] = true
	
	_ = g
}
