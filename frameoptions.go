package main

import (
	"encoding/base64"
	"fmt"
	"github.com/gorilla/mux"
	"html/template"
	"log"
	"net/http"
	"strconv"
)

type FrameOptionsPage struct {
	Result string
	TestId int
}

func FrameOptionsPassHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	id := mux.Vars(r)["id"]
	session := store.Get(w, r)
	session.Set("frameoptions"+id, "pass")

	http.ServeFile(w, r, "./static/pixel.png")
}

func FrameOptionsFailHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	id := mux.Vars(r)["id"]
	session := store.Get(w, r)
	session.Set("frameoptions"+id, "fail")

	http.ServeFile(w, r, "./static/pixel.png")
}

func FrameOptionsResultHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	result, err := session.Get("frameoptions"+mux.Vars(r)["id"])
	if err != nil {
		log.Printf("nil result frameoptions%s", mux.Vars(r)["id"])
		result = "nil"
	}

	fmt.Fprintf(w, "%s", result)
}

func FrameOptionsFrameHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	vars := mux.Vars(r)
	id := vars["id"]
	defaultResult := vars["defaultResult"]
	frameOptionsBase64 := vars["frameOptionsBase64"]

	idInt, err := strconv.ParseInt(id, 10, 0)
	if err != nil {
		log.Println(err)
		return
	}

	var result string
	if defaultResult == "pass" {
		result = "fail"
	} else {
		result = "pass"
	}

	frameOptions, err := base64.StdEncoding.DecodeString(frameOptionsBase64)
	if err != nil {
		log.Println(err)
		return
	}

	// If ?serveOnly=true, just serve the iframe: don't change the test
	// state in the session
	r.ParseForm()
	if r.Form["serveOnly"] == nil || r.Form["serveOnly"][0] != "true" {
		session.Set("frameoptions"+id, defaultResult)
	}

	w.Header().Set("X-Frame-Options", string(frameOptions))

	p := &FrameOptionsPage{Result: result,
		TestId: int(idInt)}
	t, err := template.ParseFiles("./frameoptions/frame.html")
	if err != nil {
		log.Println(err)
	}
	t.Execute(w, p)
}
