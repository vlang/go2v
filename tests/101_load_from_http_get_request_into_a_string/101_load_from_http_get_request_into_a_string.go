package main

import (
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
)

func main() {
	u := "http://" + localhost + "/hello?name=Inigo+Montoya"

	res, err := http.Get(u)
	check(err)
	buffer, err := ioutil.ReadAll(res.Body)
	res.Body.Close()
	check(err)
	s := string(buffer)

	fmt.Println("GET  response:", res.StatusCode, s)
}

const localhost = "127.0.0.1:3000"

func init() {
	http.HandleFunc("/hello", myHandler)
	startServer()
}

func myHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello %s", r.FormValue("name"))
}

func startServer() {
	listener, err := net.Listen("tcp", localhost)
	check(err)

	go http.Serve(listener, nil)
}

func check(err error) {
	if err != nil {
		panic(err)
	}
}