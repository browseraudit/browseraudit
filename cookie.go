package main

import (
	"fmt"
	"log"
	"net/http"
	"regexp"
	"time"
)

const CSP_COOKIE_NAME = "cspCookie"

const HTTPONLY_COOKIE_NAME = "httpOnlyCookie"
const HTTPONLY_COOKIE_SETVAL = "619"

const REQUEST_SECURE_COOKIE_NAME = "requestSecureCookie"
const REQUEST_SECURE_COOKIE_SETVAL = "881"

const SESSION_SECURE_COOKIE_NAME = "sessionSecureCookie"
const SESSION_SECURE_COOKIE_SETVAL = "415"

func ClearCookiesHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	expires := time.Now().Add(-240 * time.Hour)

	for _, c := range r.Cookies() {
		// Don't destroy the cookie containing the session ID (set by /test)
		if c.Name != SESSION_ID_COOKIE_NAME {
			c.Value = "."
			c.Domain = r.Header["X-Host"][0]
			c.Path = r.Header["X-Path"][0]
			c.Expires = expires

			http.SetCookie(w, c)
		}
	}

	http.ServeFile(w, r, "./static/pixel.png")
}

func CSPCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	cookieDomain := ""
	if regexp.MustCompile("^browseraudit\\.(com|org)$").MatchString(r.Header["X-Host"][0]) {
		cookieDomain = "." + r.Header["X-Host"][0]
	} else {
		cookieDomain = r.Header["X-Host"][0]
	}
	escapedDomain := regexp.MustCompile("\\.").ReplaceAllString(r.Header["X-Host"][0], "_")

	expires := time.Now().Add(5 * time.Minute)
	cookie := &http.Cookie{Name: CSP_COOKIE_NAME + "_" + escapedDomain,
		Value:   r.Header["X-Host"][0],
		Domain:  cookieDomain,
		Path:    "/",
		Expires: expires}
	http.SetCookie(w, cookie)

	http.ServeFile(w, r, "./static/pixel.png")
}

func HttpOnlyCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	expires := time.Now().Add(5 * time.Minute)
	cookie := &http.Cookie{Name: HTTPONLY_COOKIE_NAME,
		Value:    HTTPONLY_COOKIE_SETVAL,
		Domain:   ".browseraudit.com",
		Path:     "/",
		Expires:  expires,
		HttpOnly: true}
	http.SetCookie(w, cookie)
}

func SetRequestSecureCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	expires := time.Now().Add(5 * time.Minute)
	cookie := &http.Cookie{Name: REQUEST_SECURE_COOKIE_NAME,
		Value:   REQUEST_SECURE_COOKIE_SETVAL,
		Domain:  ".browseraudit.com",
		Path:    "/",
		Expires: expires,
		Secure:  true}
	http.SetCookie(w, cookie)
	
	http.ServeFile(w, r, "./static/pixel.png")
}

func GetRequestSecureCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	c, err := r.Cookie(REQUEST_SECURE_COOKIE_NAME)
	if err == nil {
		fmt.Fprintf(w, "%s", c.Value)
	} else {
		fmt.Fprintf(w, "nil")
	}
}

func SetSessionSecureCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	c, err := r.Cookie(SESSION_SECURE_COOKIE_NAME)
	if err == nil {
		session.Set(SESSION_SECURE_COOKIE_NAME, c.Value)
	} else {
		session.Set(SESSION_SECURE_COOKIE_NAME, "nil")
	}

	http.ServeFile(w, r, "./static/pixel.png")
}

func GetSessionSecureCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	c, err := session.Get(SESSION_SECURE_COOKIE_NAME)
	if err != nil {
		log.Println("nil session secure cookie")
		c = "nil"
	}

	fmt.Fprintf(w, "%s", c)
}

func GetDestroyMeHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	c, err := r.Cookie("destroyMe")
	if err == nil {
		fmt.Fprintf(w, "%s", c.Value)
	} else {
		fmt.Fprintf(w, "nil")
	}
}
