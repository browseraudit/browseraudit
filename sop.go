package main

import (
	"encoding/base64"
	"fmt"
	"github.com/gorilla/mux"
	"html/template"
	"log"
	"net/http"
	"strconv"
	"time"
)

type P2CParentPage struct {
	Script   template.HTML
	Result   string
	TestId   int
	ChildSrc template.URL
}

type P2CChildPage struct {
	Script template.HTML
}

type C2PParentPage struct {
	Script   template.HTML
	ChildSrc template.URL
}

type C2PChildPage struct {
	Script template.HTML
	Result string
	TestId int
}

type AJAXPage struct {
	Dest template.URL
}

func SOPPassHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	id := mux.Vars(r)["id"]

	// If ?serveOnly=true, just serve the iframe: don't change the test
	// state in the session cookie
	r.ParseForm()
	if r.Form["serveOnly"] == nil || r.Form["serveOnly"][0] != "true" {
		session.Set("sop"+id, "pass")
	}
}

func SOPFailHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	id := mux.Vars(r)["id"]
	
	// If ?serveOnly=true, just serve the iframe: don't change the test
	// state in the session cookie
	r.ParseForm()
	if r.Form["serveOnly"] == nil || r.Form["serveOnly"][0] != "true" {
		session.Set("sop"+id, "fail")
	}
}

func SOPResultHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	id := mux.Vars(r)["id"]

	result, err := session.Get("sop"+id)
	if err != nil {
		log.Printf("nil result sop%s", id)
		result = "nil"
	}

	fmt.Fprintf(w, "%s", result)
}

func SOPP2CParentHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	vars := mux.Vars(r)
	id := vars["id"]
	documentDomain := vars["documentDomain"]
	result := vars["result"]
	childSrcBase64 := vars["childSrcBase64"]

	// Setting document.domain to "" is different to not setting it at all, hence
	// the "none" case
	var script template.HTML
	if documentDomain == "none" {
		script = template.HTML("<script></script>")
	} else {
		script = template.HTML("<script>document.domain = \"" + documentDomain + "\";</script>")
	}

	childSrc, err := base64.StdEncoding.DecodeString(childSrcBase64)
	if err != nil {
		log.Println(err)
		return
	}

	idInt, err := strconv.ParseInt(id, 10, 0)
	if err != nil {
		log.Println(err)
		return
	}

	p := &P2CParentPage{Script: script,
		Result:   result,
		TestId:   int(idInt),
		ChildSrc: template.URL(childSrc)}
	t, err := template.ParseFiles("./sop/p2c_parent.html")
	if err != nil {
		log.Println(err)
	}
	t.Execute(w, p)
}

func SOPP2CChildHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	documentDomain := mux.Vars(r)["documentDomain"]

	// Setting document.domain to "" is different to not setting it at all, hence
	// the "none" case
	var script template.HTML
	if documentDomain == "none" {
		script = template.HTML("<script></script>")
	} else {
		script = template.HTML("<script>document.domain = \"" + documentDomain + "\";</script>")
	}

	p := &P2CChildPage{Script: script}
	t, err := template.ParseFiles("./sop/p2c_child.html")
	if err != nil {
		log.Println(err)
	}
	t.Execute(w, p)
}

func SOPC2PParentHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	vars := mux.Vars(r)
	documentDomain := vars["documentDomain"]
	childSrcBase64 := vars["childSrcBase64"]

	// Setting document.domain to "" is different to not setting it at all, hence
	// the "none" case
	var script template.HTML
	if documentDomain == "none" {
		script = template.HTML("<script></script>")
	} else {
		script = template.HTML("<script>document.domain = \"" + documentDomain + "\";</script>")
	}

	childSrc, err := base64.StdEncoding.DecodeString(childSrcBase64)
	if err != nil {
		log.Println(err)
		return
	}

	p := &C2PParentPage{Script: script,
		ChildSrc: template.URL(childSrc)}
	t, err := template.ParseFiles("./sop/c2p_parent.html")
	if err != nil {
		log.Println(err)
	}
	t.Execute(w, p)
}

func SOPC2PChildHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	vars := mux.Vars(r)
	id := vars["id"]
	documentDomain := vars["documentDomain"]
	result := vars["result"]

	// Setting document.domain to "" is different to not setting it at all, hence
	// the "none" case
	var script template.HTML
	if documentDomain == "none" {
		script = template.HTML("<script></script>")
	} else {
		script = template.HTML("<script>document.domain = \"" + documentDomain + "\";</script>")
	}

	idInt, err := strconv.ParseInt(id, 10, 0)
	if err != nil {
		log.Println(err)
		return
	}

	p := &C2PChildPage{Script: script,
		Result: result,
		TestId: int(idInt)}
	t, err := template.ParseFiles("./sop/c2p_child.html")
	if err != nil {
		log.Println(err)
	}
	t.Execute(w, p)
}

func SOPCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	vars := mux.Vars(r)
	name := vars["name"]
	value := vars["value"]
	domain := vars["domain"]
	pathBase64 := vars["pathBase64"]

	path, err := base64.StdEncoding.DecodeString(pathBase64)
	if err != nil {
		log.Println(err)
		return
	}

	// If ?serveOnly=true, just serve the iframe: don't set any cookies
	r.ParseForm()
	if r.Form["serveOnly"] == nil || r.Form["serveOnly"][0] != "true" {
		expires := time.Now().Add(time.Minute)
		cookie := &http.Cookie{Name: name, Value: value, Expires: expires}
		if domain != "none" {
			cookie.Domain = domain
		}
		if string(path) != "none" {
			cookie.Path = string(path)
		}
		http.SetCookie(w, cookie)
	}

	http.ServeFile(w, r, "./static/pixel.png")
}

func SOPSaveCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	name := mux.Vars(r)["name"]
	c, err := r.Cookie(name)
	if err == nil {
		session.Set(name, c.Value)
	} else {
		session.Set(name, "none")
	}

	http.ServeFile(w, r, "./static/pixel.png")
}

func SOPGetCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	name := mux.Vars(r)["name"]
	c, err := session.Get(name)
	if err != nil {
		log.Printf("nil result %s", name)
		c = "nil"
	}

	fmt.Fprintf(w, "%s", c)
}

func SOPAJAXHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	destBase64 := mux.Vars(r)["destBase64"]

	dest, err := base64.StdEncoding.DecodeString(destBase64)
	if err != nil {
		log.Println(err)
		return
	}

	p := &AJAXPage{Dest: template.URL(dest)}
	t, err := template.ParseFiles("./sop/ajax.html")
	if err != nil {
		log.Println(err)
	}
	t.Execute(w, p)
}
