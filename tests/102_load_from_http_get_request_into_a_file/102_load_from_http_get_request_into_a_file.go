package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"os"
)

func main() {
	err := saveGetResponse()
	check(err)
	err = readFile()
	check(err)

	fmt.Println("Done.")
}

func saveGetResponse() error {
	u := "http://" + localhost + "/hello?name=Inigo+Montoya"

	fmt.Println("Making GET request")
	resp, err := http.Get(u)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return fmt.Errorf("Status: %v", resp.Status)
	}

	fmt.Println("Saving data to file")
	out, err := os.Create("/tmp/result.txt")
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, resp.Body)
	if err != nil {
		return err
	}
	return nil
}

func readFile() error {
	fmt.Println("Reading file")
	buffer, err := ioutil.ReadFile("/tmp/result.txt")
	if err != nil {
		return err
	}
	fmt.Printf("Saved data is %q\n", string(buffer))
	return nil
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
