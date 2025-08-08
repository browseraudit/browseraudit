package main

import (
	"encoding/base64"
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

func CorsAllowOriginHandler(w http.ResponseWriter, r *http.Request) {
	originBase64 := mux.Vars(r)["originBase64"]
	origin, err := base64.StdEncoding.DecodeString(originBase64)
	if err != nil {
		log.Println(err)
		return
	}

	if string(origin) != "none" {
		w.Header().Set("Access-Control-Allow-Origin", string(origin))
	}
}

func CorsAllowMethodsHandler(w http.ResponseWriter, r *http.Request) {
	methodsBase64 := mux.Vars(r)["methodsBase64"]
	methods, err := base64.StdEncoding.DecodeString(methodsBase64)
	if err != nil {
		log.Println(err)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "https://browseraudit.com")
	if string(methods) != "none" {
		w.Header().Set("Access-Control-Allow-Methods", string(methods))
	}
}

func CorsAllowHeadersHandler(w http.ResponseWriter, r *http.Request) {
	headersBase64 := mux.Vars(r)["headersBase64"]
	headers, err := base64.StdEncoding.DecodeString(headersBase64)
	if err != nil {
		log.Println(err)
		return
	}

	w.Header().Set("Access-Control-Allow-Origin", "https://browseraudit.com")
	if string(headers) != "none" {
		w.Header().Set("Access-Control-Allow-Headers", string(headers))
	}
}

func CorsExposedHeadersHandler(w http.ResponseWriter, r *http.Request) {
	headersBase64 := mux.Vars(r)["headersBase64"]
	headers, err := base64.StdEncoding.DecodeString(headersBase64)
	if err != nil {
		log.Println(err)
		return
	}

	DontCache(&w)
	w.Header().Set("Last-Modified", "Sun, 15 Jun 2014 18:40:03 GMT")
	w.Header().Set("Content-Language", "en")
	w.Header().Set("Access-Control-Allow-Origin", "https://browseraudit.com")
	if string(headers) != "none" {
		w.Header().Set("Access-Control-Expose-Headers", string(headers))
	}
}

func CorsAllowCredentialsHandler(w http.ResponseWriter, r *http.Request) {
	allowOrigin64 := mux.Vars(r)["originBase64"]
	allowOrigin, err := base64.StdEncoding.DecodeString(allowOrigin64)
	if err != nil {
		log.Println(err)
		return
	}
	allowCredentials64 := mux.Vars(r)["credentialsBase64"]
	allowCredentials, err := base64.StdEncoding.DecodeString(allowCredentials64)
	if err != nil {
		log.Println(err)
		return
	}

	allowCredentialsStr := string(allowCredentials)
	if allowCredentialsStr == "true" {
		w.Header().Set("Access-Control-Allow-Credentials", allowCredentialsStr)
	}
	w.Header().Set("Access-Control-Allow-Origin", string(allowOrigin))
}
