package main

import (
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
)

func main() {
	formValues := url.Values{
		"who": []string{"Alice"},
	}
	u := "http://" + localhost + "/hello"

	response, err := http.PostForm(u, formValues)
	check(err)
	buffer, err := ioutil.ReadAll(response.Body)
	check(err)
	fmt.Println("POST response:", response.StatusCode, string(buffer))

	response, err = http.Get(u)
	check(err)
	buffer, err = ioutil.ReadAll(response.Body)
	check(err)
	fmt.Println("GET  response:", response.StatusCode, string(buffer))
}

const localhost = "127.0.0.1:3000"

func init() {
	http.HandleFunc("/hello", myHandler)
	startServer()
}

func myHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintf(w, "Refusing request verb %q", r.Method)
		return
	}
	fmt.Fprintf(w, "Hello %s (POST)", r.FormValue("who"))
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
