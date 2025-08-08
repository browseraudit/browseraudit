package main

import (
	"encoding/base64"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"
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
	protocol := RequestScheme(r)

	if protocol == "http" || protocol == "https" {
		session.Set(PROTOCOL_KEY, protocol)
	} else {
		log.Printf("Unrecognised protocol %s", protocol)
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
