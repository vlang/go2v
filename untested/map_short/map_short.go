package main

type Vertex struct {
	Lat, Long float64
}

func main() {
	var n = map[string]Vertex{
		"A":      {40.68433, -74.39967},
		"Google": {37.42202, -122.08408},
	}
}
