package main

func foo() bool {
	fosterParenting := true
	defer func() {
		fosterParenting = false
		println("hello")
	}()
	return fosterParenting
}
