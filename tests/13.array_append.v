module main

fn main() {
	mut s := []int{}
	s << 1
	s << 2, 3, 4
	mut a := [4, 5, 6]
	mut b := [1, 2, 3]
	b << a
}
