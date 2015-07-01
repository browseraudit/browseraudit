package main

import (
	"encoding/base64"
	"fmt"
	"github.com/gorilla/mux"
	"log"
	"net/http"
)

const PROTOCOL_KEY = "protocol"

func SetHSTSHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	policyBase64 := mux.Vars(r)["policyBase64"]
	policy, err := base64.StdEncoding.DecodeString(policyBase64)
	if err != nil {
		log.Println(err)
	}
	w.Header().Set("Strict-Transport-Security", string(policy))
	http.ServeFile(w, r, "./static/pixel.png")
}

func ClearHSTSHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	w.Header().Set("Strict-Transport-Security", "max-age=0")
	http.ServeFile(w, r, "./static/pixel.png")
}

func SetProtocolHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	if r.Header["X-Scheme"][0] == "http" || r.Header["X-Scheme"][0] == "https" {
		session.Set(PROTOCOL_KEY, r.Header["X-Scheme"][0])
	} else {
		log.Printf("Unrecognised protocol %s", r.Header["X-Scheme"][0])
	}

	http.ServeFile(w, r, "./static/pixel.png")
}

func GetProtocolHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	val, err := session.Get(PROTOCOL_KEY)
	if err != nil {
		log.Println("nil " + PROTOCOL_KEY)
		val = "nil"
	}

	fmt.Fprintf(w, "%s", val)
}
