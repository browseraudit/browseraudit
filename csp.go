package main

import (
	"encoding/base64"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"regexp"

	"github.com/gorilla/mux"
)

type CSPTemplate struct {
	SessionID    string
	CookieDomain string
}

func CSPServeHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)
	id := mux.Vars(r)["id"]
	r.ParseForm()

	// If there is a "policy" parameter in the query string, send back the
	// Base64-decoded Content-Security-Policy: HTTP header
	if r.Form["policy"] != nil && r.Form["policy"][0] != "" {
		policyBase64 := r.Form["policy"][0]
		policy, err := base64.StdEncoding.DecodeString(policyBase64)
		if err != nil {
			log.Println(err)
		}

		// Add Report-To header and required CORS headers for CSP tests related to Reporting API
		if id == "267" {
			w.Header().Set("Reporting-Endpoints", `endpoint-1="https://browseraudit.com/csp/pass/267/emptyhtml"`)
			w.Header().Set("Report-To", `{"group":"endpoint-1","max_age":31536000,"endpoints":[{"url":"https://browseraudit.com/csp/pass/267/emptyhtml"}],"include_subdomains":true}`)
			w.Header().Set("Access-Control-Allow-Origin", "https://browseraudit.com")
			w.Header().Set("Access-Control-Allow-Methods", "POST")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		}

		w.Header().Set("Content-Security-Policy", string(policy))
	}

	// If there is a "defaultResult" parameter in the query string, set the
	// default result for this CSP test in the session data
	if r.Form["defaultResult"] != nil && r.Form["defaultResult"][0] != "" {
		defaultResult := r.Form["defaultResult"][0]
		session.Set("csp"+id, defaultResult)
	}

	CSPServeFile(w, r)
}

func CSPPassHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)
	id := mux.Vars(r)["id"]
	r.ParseForm()

	session.Set("csp"+id, "pass")

	CSPServeFile(w, r)
}

func CSPFailHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)
	id := mux.Vars(r)["id"]
	r.ParseForm()

	session.Set("csp"+id, "fail")

	CSPServeFile(w, r)
}

func CSPServeFile(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	// Parameters passed in the path of the URI:
	// "id" specifies the CSP test ID
	id := mux.Vars(r)["id"]
	// "file" specifies a particular file to be served
	file := mux.Vars(r)["file"]

	r.ParseForm()

	// Set the Access-Control-Allow-*: HTTP headers, if required
	if r.Form["corsOrigin"] != nil && r.Form["corsOrigin"][0] != "" {
		// "corsOrigin" specifies the Access-Control-Allow-Origin: HTTP
		// header to be included in the response
		w.Header().Set("Access-Control-Allow-Origin", r.Form["corsOrigin"][0])
	}
	if r.Form["corsMethod"] != nil && r.Form["corsMethod"][0] != "" {
		// "corsMethod" specifies the Access-Control-Allow-Method: HTTP
		// header to be included in the response
		w.Header().Set("Access-Control-Allow-Method", r.Form["corsMethod"][0])
	}

	// Serve a file as directed by the "file" segment of the URI path
	switch {
	// First, handle the static files
	case file == "emptyhtml":
		http.ServeFile(w, r, "./csp/empty.html")

	case file == "emptycss":
		w.Header().Set("Content-Type", "text/css")
		fmt.Fprintln(w, "/* Empty CSS */")

	case file == "emptyjs":
		w.Header().Set("Content-Type", "text/javascript")
		fmt.Fprintln(w, "// Empty JS")

	case file == "emptyjson":
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, "{}")

	case file == "emptyes":
		// We need to send a non-200 HTTP status code and/or a Content-Type
		// other than text/event-stream to prevent Chrome from making
		// endless requests to this "stream"
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprintln(w, "data: 1\n\n")

	case file == "oktext":
		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprintln(w, "ok")

	case file == "png":
		http.ServeFile(w, r, "./static/pixel.png")

	case file == "swf":
		http.ServeFile(w, r, "./csp/minimal.swf")

	case file == "mp3":
		http.ServeFile(w, r, "./csp/mpthreetest.mp3")

	case file == "mp4":
		http.ServeFile(w, r, "./csp/small.mp4")

	case file == "eot":
		//w.Header().Set("Content-Type", "application/vnd.ms-fontobject")
		//fileToServe = "./csp/BrowserAuditTestFont.eot"
		http.ServeFile(w, r, "./csp/BrowserAuditTestFont.eot")

	case file == "woff":
		//w.Header().Set("Content-Type", "application/font-woff")
		//fileToServe = "./csp/BrowserAuditTestFont.woff"
		http.ServeFile(w, r, "./csp/BrowserAuditTestFont.woff")

	case file == "ttf":
		//w.Header().Set("Content-Type", "application/x-font-ttf")
		//fileToServe = "./csp/BrowserAuditTestFont.ttf"
		http.ServeFile(w, r, "./csp/BrowserAuditTestFont.ttf")

	case file == "svg":
		//w.Header().Set("Content-Type", "image/svg+xml")
		//fileToServe = "./csp/BrowserAuditTestFont.svg"
		http.ServeFile(w, r, "./csp/BrowserAuditTestFont.svg")

	// Now, handle the dynamic (i.e. parameterised) files
	case regexp.MustCompile("^param-").MatchString(file):
		fileToServe := ""

		switch {
		// param-html => iframe HTML file
		case file == "param-html":
			w.Header().Set("Content-Type", "text/html")
			fileToServe = "./csp/" + id + ".html"

		// param-htmlb => nested iframe HTML file
		case file == "param-htmlb":
			w.Header().Set("Content-Type", "text/html")
			fileToServe = "./csp/" + id + "-b.html"

		// param-css => external stylesheet
		case file == "param-css":
			w.Header().Set("Content-Type", "text/css")
			fileToServe = "./csp/" + id + ".css"

		// param-cssb => nested external stylesheet
		case file == "param-cssb":
			w.Header().Set("Content-Type", "text/css")
			fileToServe = "./csp/" + id + "-b.css"
		} // end switch

		cookieDomain := ""
		if r.Form["cookieDomain"] != nil && r.Form["cookieDomain"][0] != "" {
			// "cookieDomain" is present for document.cookie
			// allow-same-origin sandbox tests, and controls
			// the cookie that should be attempted to be
			// read by a script in the child iframe
			cookieDomain = r.Form["cookieDomain"][0]
		}

		// Serve dynamic file. browseraudit cookie is guaranteed
		// to exist, due to earlier call to addManualCookie()
		session := store.Get(w, r)
		p := &CSPTemplate{
			SessionID:    session.Id,
			CookieDomain: cookieDomain,
		}

		t, err := template.ParseFiles(fileToServe)
		if err != nil {
			log.Println(err)
		}

		t.Execute(w, p)
	} // end switch
}

func CSPResultHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	session := store.Get(w, r)

	id := mux.Vars(r)["id"]
	result, err := session.Get("csp" + id)
	if err != nil {
		log.Printf("nil result csp%s\n", id)
		result = "nil"
	}

	fmt.Fprintf(w, "%s", result)
}
