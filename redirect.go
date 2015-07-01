package main

import (
	"encoding/base64"
	"github.com/gorilla/mux"
	"log"
	"net/http"
)

func RedirectHandler(w http.ResponseWriter, r *http.Request) {
	destBase64 := mux.Vars(r)["dest"]

	dest, err := base64.StdEncoding.DecodeString(destBase64)
	if err != nil {
		log.Println(err)
	}

	http.Redirect(w, r, string(dest), 301)
}
