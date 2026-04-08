package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	D, err := prepareTestDirTree()
	if err != nil {
		fmt.Printf("unable to create test dir tree: %v\n", err)
		return
	}
	defer os.RemoveAll(D)

	L := []string{}
	err = filepath.Walk(D, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			fmt.Printf("failure accessing a path %q: %v\n", path, err)
			return err
		}
		for _, ext := range []string{".jpg", ".jpeg", ".png"} {
			if strings.HasSuffix(path, ext) {
				L = append(L, path)
				break
			}
		}
		return nil
	})

	fmt.Println(err)
	fmt.Println(strings.Join(L, "\n"))
}

func prepareTestDirTree() (string, error) {
	tmpDir, err := ioutil.TempDir("", "")
	if err != nil {
		return "", fmt.Errorf("error creating temp directory: %v\n", err)
	}

	for _, subdir := range []string{
		"2018/nov",
		"2018/dec",
		"2019/jan",
		"2019/feb",
	} {
		err = os.MkdirAll(filepath.Join(tmpDir, subdir), 0755)
		if err != nil {
			os.RemoveAll(tmpDir)
			return "", err
		}
	}

	for _, fpath := range []string{
		"2018/nov/a.txt",
		"2018/nov/b.jpg",
		"2018/c.png",
		"2019/jan/d.mp3",
		"2019/jan/e.jpg",
		"2019/jan/f.jpeg",
		"2019/feb/g.jpg",
		"2019/feb/g.jpeg",
		"h.jpg",
	} {
		_, err := os.Create(filepath.Join(tmpDir, fpath))
		if err != nil {
			os.RemoveAll(tmpDir)
			return "", err
		}
	}

	return tmpDir, nil
}
