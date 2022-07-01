package main

import "fmt"

func main() {
	fmt.Printf("%d", 12345) // 12345
	fmt.Printf("%v", 12345) // 12345"
	fmt.Printf("%t", true)  // true

	fmt.Println()

	// basic string
	fmt.Printf("%s", "abc")              // abc
	fmt.Printf("%q", "abc")              // "abc"
	fmt.Printf("%x", "abc")              // 616263
	fmt.Printf("%x", "\xff\xf0\x0f\xff") // fff00fff
	fmt.Printf("%X", "\xff\xf0\x0f\xff") // FFF00FFF
	fmt.Printf("%x", "")                 //
	fmt.Printf("% x", "")                //
	fmt.Printf("%#x", "")                //
	fmt.Printf("%# x", "")               //
	fmt.Printf("%x", "xyz")              // 78797a
	fmt.Printf("%X", "xyz")              // 78797A
	fmt.Printf("% x", "xyz")             // 78 79 7a
	fmt.Printf("% X", "xyz")             // 78 79 7A
	fmt.Printf("%#x", "xyz")             // 0x78797a
	fmt.Printf("%#X", "xyz")             // 0X78797A
	fmt.Printf("%# x", "xyz")            // 0x78 0x79 0x7a
	fmt.Printf("%# X", "xyz")            // 0X78 0X79 0X7A

	fmt.Println()

	// basic bytes
	fmt.Printf("%s", []byte("abc"))           // abc
	fmt.Printf("%s", [3]byte{'a', 'b', 'c'})  // abc
	fmt.Printf("%s", &[3]byte{'a', 'b', 'c'}) // &abc
}
