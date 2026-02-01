package main

import (
	"fmt"
	"log"
	"strings"

	"io/ioutil"
	"net"
	"net/http"
)

func main() {
	contentType := "text/plain"
	bodyString := "This is my request payload"
	contentLength := int64(len(bodyString))
	body := strings.NewReader(bodyString)
	u := "http://" + localhost + "/hello"

	req, err := http.NewRequest("PUT", u, body)
	if err != nil {
		log.Fatal(err)
	}
	req.Header.Set("Content-Type", contentType)
	req.ContentLength = contentLength
	response, err := http.DefaultClient.Do(req)
	
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
	if r.Method != "PUT" {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintf(w, "Refusing request verb %q", r.Method)
		return
	}
	fmt.Fprintf(w, "Hello PUT :)")
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
