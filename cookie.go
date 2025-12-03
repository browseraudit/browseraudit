package main

import (
	"fmt"
	"html/template"
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

	path := regexp.MustCompile("(.*/).*?$").ReplaceAllString(r.URL.Path, "$1")
	expires := time.Now().Add(-240 * time.Hour)

	for _, c := range r.Cookies() {
		// Don't destroy the cookie containing the session ID (set by /test)
		if c.Name != SESSION_ID_COOKIE_NAME {
			c.Value = "."
			c.Domain = RequestHost(r)
			c.Path = path
			c.Expires = expires

			http.SetCookie(w, c)
		}
	}

	http.ServeFile(w, r, "./static/pixel.png")
}

func CSPCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	cookieDomain := ""
	if regexp.MustCompile("^browseraudit\\.(com|org)$").MatchString(RequestHost(r)) {
		cookieDomain = "." + RequestHost(r)
	} else {
		cookieDomain = RequestHost(r)
	}
	escapedDomain := regexp.MustCompile("\\.").ReplaceAllString(RequestHost(r), "_")

	expires := time.Now().Add(5 * time.Minute)
	cookie := &http.Cookie{Name: CSP_COOKIE_NAME + "_" + escapedDomain,
		Value:   RequestHost(r),
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
		template.HTMLEscape(w, []byte(c.Value))
	} else {
		fmt.Fprintf(w, "nil")
	}
}

func SetSessionSecureCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)
	c, err := r.Cookie(SESSION_SECURE_COOKIE_NAME)
	if err != nil || r.Header.Get("X-Forwarded-Proto") == "https" {
		session.Set(SESSION_SECURE_COOKIE_NAME, "nil")
	} else {
		session.Set(SESSION_SECURE_COOKIE_NAME, c.Value)
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

	template.HTMLEscape(w, []byte(c))
}

func GetDestroyMeHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	c, err := r.Cookie("destroyMe")
	if err == nil {
		template.HTMLEscape(w, []byte(c.Value))
	} else {
		fmt.Fprintf(w, "nil")
	}
}
