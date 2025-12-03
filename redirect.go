package main

import (
	"encoding/base64"
	"log"
	"strings"
	"net/http"

	"github.com/gorilla/mux"
)

func RedirectHandler(w http.ResponseWriter, r *http.Request) {
	destBase64 := mux.Vars(r)["dest"]

	dest, err := base64.StdEncoding.DecodeString(destBase64)
	if err != nil {
		log.Println(err)
		http.Error(w, "Invalid redirect destination", http.StatusBadRequest)
		return
	}

	destStr := string(dest)

	//Ensure the redirect is to a safe, relative path on the same domain.

	if len(destStr) == 0 || destStr[0] != '/' {
		http.Error(w, "Redirects must be to a path on the same domain (e.g., /some/path)", http.StatusBadRequest)
		return
	}

	//Prevent cases like /%0A//example.com 
	if len(destStr) > 1 {
		secondChar := destStr[1]
		if !((secondChar >= 'a' && secondChar <= 'z') ||
			(secondChar >= 'A' && secondChar <= 'Z') ||
			(secondChar >= '0' && secondChar <= '9') ||
			secondChar == '-') {
			http.Error(w, "Redirect path contains an invalid character after the initial slash", http.StatusBadRequest)
			return
		}
	}

	// Prevent protocol-relative URLs and any ambiguous backslash characters.
	if strings.Contains(destStr, "//") || strings.Contains(destStr, "\\") {
		http.Error(w, "Redirect path contains invalid sequences (e.g., // or /\\)", http.StatusBadRequest)
		return
	}

	// Prevent path traversal
	if strings.Contains(destStr, "..") {
		http.Error(w, "Redirect path cannot contain '..'", http.StatusBadRequest)
		return
	}

	http.Redirect(w, r, destStr, http.StatusMovedPermanently)
}
