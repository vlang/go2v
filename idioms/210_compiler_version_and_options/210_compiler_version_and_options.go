package main

import "runtime"

func main() {
	version := runtime.Version()

	println(version)
}
