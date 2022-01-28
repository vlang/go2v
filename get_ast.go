package main

import (
	"flag"
	"fmt"
	"go/parser"
	"go/token"
	"io"
	"log"
	"os"
	"reflect"
)

//TODO: greatly simplify this code, for now I just copied the a piece of code given by *@JalonSolov#0531* on Discord

func main() {
	pathname := ""
	outpathname := ""
	flag.StringVar(&pathname, "f", "", "file to process")
	flag.StringVar(&outpathname, "o", "", "file to output")
	fmt.Println(pathname)
	fmt.Println(outpathname)

	flag.Parse()

	fset := token.NewFileSet()
	node, err := parser.ParseFile(fset, pathname, nil, parser.ParseComments)
	if err != nil {
		log.Fatal(err)
	}

	f, err := os.OpenFile(outpathname, os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0600)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	fprint(f, fset, node, NotNilFilter)
	//TODO: find if there is a way to just use the built-in ast.Print() function, the only differences are:
	/*
		FROM ast/print.go:
		86
		87  - var indent = []byte(".  ")
		87  + var indent = []byte(" ")
		88
		...
		100	 	} else if p.last == '\n' {
		101 -	_, err = fmt.Fprintf(p.output, "%6d  ", p.line)
		102 -	if err != nil {
		103 -		return
		104 -	}
		105  	for j := p.indent; j > 0; j-- {
	*/
	// Maybe find a way to overwrite the variable `indent` and the function `printer.Write`
}

// A FieldFilter may be provided to Fprint to control the output.
type FieldFilter func(name string, value reflect.Value) bool

// NotNilFilter returns true for field values that are not nil;
// it returns false otherwise.
func NotNilFilter(_ string, v reflect.Value) bool {
	switch v.Kind() {
	case reflect.Chan, reflect.Func, reflect.Interface, reflect.Map, reflect.Ptr, reflect.Slice:
		return !v.IsNil()
	}
	return true
}

func fprint(w io.Writer, fset *token.FileSet, x interface{}, f FieldFilter) (err error) {
	// setup printer
	p := printer{
		output: w,
		fset:   fset,
		filter: f,
		ptrmap: make(map[interface{}]int),
		last:   '\n', // force printing of line number on first line
	}

	// install error handler
	defer func() {
		if e := recover(); e != nil {
			err = e.(localError).err // re-panics if it's not a localError
		}
	}()

	// print x
	if x == nil {
		p.printf("nil\n")
		return
	}
	p.print(reflect.ValueOf(x))
	p.printf("\n")

	return
}

type printer struct {
	output io.Writer
	fset   *token.FileSet
	filter FieldFilter
	ptrmap map[interface{}]int // *T -> line number
	indent int                 // current indentation level
	last   byte                // the last byte processed by Write
	line   int                 // current line number
}

var indent = []byte(" ")

func (p *printer) Write(data []byte) (n int, err error) {
	var m int
	for i, b := range data {
		// invariant: data[0:n] has been written
		if b == '\n' {
			m, err = p.output.Write(data[n : i+1])
			n += m
			if err != nil {
				return
			}
			p.line++
		} else if p.last == '\n' {
			for j := p.indent; j > 0; j-- {
				_, err = p.output.Write(indent)
				if err != nil {
					return
				}
			}
		}
		p.last = b
	}
	if len(data) > n {
		m, err = p.output.Write(data[n:])
		n += m
	}
	return
}

// localError wraps locally caught errors so we can distinguish
// them from genuine panics which we don't want to return as errors.
type localError struct {
	err error
}

// printf is a convenience wrapper that takes care of print errors.
func (p *printer) printf(format string, args ...interface{}) {
	if _, err := fmt.Fprintf(p, format, args...); err != nil {
		panic(localError{err})
	}
}

func IsExported(name string) bool { return token.IsExported(name) }

func (p *printer) print(x reflect.Value) {
	if !NotNilFilter("", x) {
		p.printf("nil")
		return
	}

	switch x.Kind() {
	case reflect.Interface:
		p.print(x.Elem())

	case reflect.Map:
		p.printf("%s (len = %d) {", x.Type(), x.Len())
		if x.Len() > 0 {
			p.indent++
			p.printf("\n")
			for _, key := range x.MapKeys() {
				p.print(key)
				p.printf(": ")
				p.print(x.MapIndex(key))
				p.printf("\n")
			}
			p.indent--
		}
		p.printf("}")

	case reflect.Ptr:
		p.printf("*")
		// type-checked ASTs may contain cycles - use ptrmap
		// to keep track of objects that have been printed
		// already and print the respective line number instead
		ptr := x.Interface()
		if line, exists := p.ptrmap[ptr]; exists {
			p.printf("(obj @ %d)", line)
		} else {
			p.ptrmap[ptr] = p.line
			p.print(x.Elem())
		}

	case reflect.Array:
		p.printf("%s {", x.Type())
		if x.Len() > 0 {
			p.indent++
			p.printf("\n")
			for i, n := 0, x.Len(); i < n; i++ {
				p.printf("%d: ", i)
				p.print(x.Index(i))
				p.printf("\n")
			}
			p.indent--
		}
		p.printf("}")

	case reflect.Slice:
		if s, ok := x.Interface().([]byte); ok {
			p.printf("%#q", s)
			return
		}
		p.printf("%s (len = %d) {", x.Type(), x.Len())
		if x.Len() > 0 {
			p.indent++
			p.printf("\n")
			for i, n := 0, x.Len(); i < n; i++ {
				p.printf("%d: ", i)
				p.print(x.Index(i))
				p.printf("\n")
			}
			p.indent--
		}
		p.printf("}")

	case reflect.Struct:
		t := x.Type()
		p.printf("%s {", t)
		p.indent++
		first := true
		for i, n := 0, t.NumField(); i < n; i++ {
			// exclude non-exported fields because their
			// values cannot be accessed via reflection
			if name := t.Field(i).Name; IsExported(name) {
				value := x.Field(i)
				if p.filter == nil || p.filter(name, value) {
					if first {
						p.printf("\n")
						first = false
					}
					p.printf("%s: ", name)
					p.print(value)
					p.printf("\n")
				}
			}
		}
		p.indent--
		p.printf("}")

	default:
		v := x.Interface()
		switch v := v.(type) {
		case string:
			// print strings in quotes
			p.printf("%q", v)
			return
		case token.Pos:
			// position values can be printed nicely if we have a file set
			if p.fset != nil {
				p.printf("%s", p.fset.Position(v))
				return
			}
		}
		// default
		p.printf("%v", v)
	}
}
