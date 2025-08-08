package main

import (
	"fmt"
	"log"
	"net/http"
)

const IMAGE_REFERER_KEY = "image_referer"

func SetRefererHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)
	session.Set(IMAGE_REFERER_KEY, r.Referer())

	http.ServeFile(w, r, "./static/pixel.png")
}

func GetRefererHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	referer, err := session.Get(IMAGE_REFERER_KEY)
	// Handle possible autoupgrade when testing referer over unsecure connection
	if err != nil || r.Header.Get("X-Forwarded-Proto") == "https" {
		log.Println("nil " + IMAGE_REFERER_KEY)
		referer = ""
	}

	fmt.Fprintf(w, "%s", referer)
}

func GetReferrerPolicyHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	referer, err := session.Get(IMAGE_REFERER_KEY)
	if err != nil {
		log.Println("nil " + IMAGE_REFERER_KEY)
		referer = ""
	}

	fmt.Fprintf(w, "%s", referer)
}
