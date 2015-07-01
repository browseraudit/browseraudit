package main

import (
	"code.google.com/p/gcfg"
	"fmt"
	"github.com/gorilla/mux"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/oschwald/geoip2-golang"
	"log"
	"net/http"
	"strings"
)

// Structure of server.cfg (INI file):
type Config struct {
	HTTPServer struct {
		Host string
		Port int
		SessionIDSalt string
		GeoIP2Database string
	}
	Memcached struct {
		Host string
		Port int
	}
	Database struct {
		Host string
		Port int
		Username string
		Password string
		DatabaseName string `gcfg:"dbname"`
	}
}

var cfg Config
var store *BASessionStore
var db *sqlx.DB
var geoipDB *geoip2.Reader

func main() {
	var err error // This allows us to use the global vars geoipDB and db with :=
	
	// Read configuration file
	if err := gcfg.ReadFileInto(&cfg, "server.cfg"); err != nil {
		log.Fatalf("Could not read server configuration file 'server.cfg': %s\n", err)
	}

	// Read GeoLite2 database from file
	if geoipDB, err = geoip2.Open(cfg.HTTPServer.GeoIP2Database); err != nil {
		log.Fatalf("Could not read GeoIP2/GeoLite2 database file '%s': %s\n", cfg.HTTPServer.GeoIP2Database, err)
	}

	// Connect to Memcached server and create a new session store backed by it
	store = NewBASessionStore(cfg.Memcached.Host, cfg.Memcached.Port)

	r := mux.NewRouter()
	r.HandleFunc("/", HomeHandler)
	r.HandleFunc("/test", TestHandler)

	r.HandleFunc("/category_tree", JSONCategoryTreeHandler)
	r.HandleFunc("/test_suite/{catids}", GenerateTestSuiteHandler)

	r.HandleFunc("/clear_cookies", ClearCookiesHandler)
	r.HandleFunc("/sop/path/clear_cookies", ClearCookiesHandler)
	r.HandleFunc("/set_sessid_cookie/{sessionID:[0-9a-f]+}", SetSessionIDCookieHandler)

	r.HandleFunc("/csp_cookie", CSPCookieHandler)
	r.HandleFunc("/httponly_cookie", HttpOnlyCookieHandler)
	r.HandleFunc("/set_request_secure_cookie", SetRequestSecureCookieHandler)
	r.HandleFunc("/get_request_secure_cookie", GetRequestSecureCookieHandler)
	r.HandleFunc("/set_session_secure_cookie", SetSessionSecureCookieHandler)
	r.HandleFunc("/get_session_secure_cookie", GetSessionSecureCookieHandler)
	r.HandleFunc("/get_destroy_me", GetDestroyMeHandler)

	r.HandleFunc("/set_referer", SetRefererHandler)
	r.HandleFunc("/get_referer", GetRefererHandler)

	r.HandleFunc("/set_hsts/{id:[0-9]+}/{policyBase64}", SetHSTSHandler)
	r.HandleFunc("/clear_hsts/{id:[0-9]+}", ClearHSTSHandler)
	r.HandleFunc("/set_protocol/{id:[0-9]+}", SetProtocolHandler)
	r.HandleFunc("/get_protocol/{id:[0-9]+}", GetProtocolHandler)

	r.HandleFunc("/csp/serve/{id:[0-9]+}/{file:[a-z0-9-]+}", CSPServeHandler)
	r.HandleFunc("/csp/pass/{id:[0-9]+}/{file:[a-z0-9-]+}", CSPPassHandler)
	r.HandleFunc("/csp/fail/{id:[0-9]+}/{file:[a-z0-9-]+}", CSPFailHandler)
	r.HandleFunc("/csp/result/{id:[0-9]+}", CSPResultHandler)

	r.HandleFunc("/sop/pass/{id:[0-9]+}", SOPPassHandler)
	r.HandleFunc("/sop/fail/{id:[0-9]+}", SOPFailHandler)
	r.HandleFunc("/sop/result/{id:[0-9]+}", SOPResultHandler)
	r.HandleFunc("/sop/p2c/parent/{id:[0-9]+}/{documentDomain:[a-z.]+}/{result:pass|fail}/{childSrcBase64}", SOPP2CParentHandler)
	r.HandleFunc("/sop/p2c/child/{documentDomain:[a-z.]+}", SOPP2CChildHandler)
	r.HandleFunc("/sop/c2p/parent/{documentDomain:[a-z.]+}/{childSrcBase64}", SOPC2PParentHandler)
	r.HandleFunc("/sop/c2p/child/{id:[0-9]+}/{documentDomain:[a-z.]+}/{result:pass|fail}", SOPC2PChildHandler)
	r.HandleFunc("/sop/cookie/{name}/{value}/{domain:[a-z.]+}/{pathBase64}", SOPCookieHandler)
	r.HandleFunc("/sop/save_cookie/{name}", SOPSaveCookieHandler)
	r.HandleFunc("/sop/get_cookie/{name}", SOPGetCookieHandler)
	r.HandleFunc("/sop/path/cookie/{name}/{value}/{domain:[a-z.]+}/{pathBase64}", SOPCookieHandler)
	r.HandleFunc("/sop/path/save_cookie/{name}", SOPSaveCookieHandler)
	r.HandleFunc("/sop/ajax/{id:[0-9]+}/{result:pass|fail}/{destBase64}", SOPAJAXHandler)

	r.HandleFunc("/frameoptions/pass/{id:[0-9]+}", FrameOptionsPassHandler)
	r.HandleFunc("/frameoptions/fail/{id:[0-9]+}", FrameOptionsFailHandler)
	r.HandleFunc("/frameoptions/result/{id:[0-9]+}", FrameOptionsResultHandler)
	r.HandleFunc("/frameoptions/{id:[0-9]+}/{defaultResult:pass|fail}/{frameOptionsBase64}", FrameOptionsFrameHandler)

	r.HandleFunc("/cors/allow-origin/{originBase64}", CorsAllowOriginHandler)
	r.HandleFunc("/cors/allow-methods/{methodsBase64}", CorsAllowMethodsHandler)
	r.HandleFunc("/cors/allow-headers/{headersBase64}", CorsAllowHeadersHandler)
	r.HandleFunc("/cors/exposed-headers/{headersBase64}", CorsExposedHeadersHandler)

	r.HandleFunc("/results/{id:[0-9]+}/{passkey:[0-9a-f]+}", ResultsPageHandler)
	r.HandleFunc("/suite_execution/get/{id:[0-9]+}/{passkey:[0-9a-f]+}", GetSuiteExecutionHandler)
	r.HandleFunc("/suite_execution/put", PutSuiteExecutionHandler)

	r.HandleFunc("/redirect/{dest}", RedirectHandler)

	// Connect to the database server
	var dbDataSource = fmt.Sprintf("host=%s port=%d user='%s' password='%s' dbname='%s'",
		cfg.Database.Host,
		cfg.Database.Port,
		strings.Replace(cfg.Database.Username, "'", "\\'", -1),
		strings.Replace(cfg.Database.Password, "'", "\\'", -1),
		strings.Replace(cfg.Database.DatabaseName, "'", "\\'", -1))	
	if db, err = sqlx.Connect("postgres", dbDataSource); err != nil {
		log.Fatalf("Could not connect to database server: %s\n", err)
	}

	// Start listening on the given IP address and port
	http.Handle("/", r)
	var httpListenAddr = fmt.Sprintf("%s:%d",
		cfg.HTTPServer.Host,
		cfg.HTTPServer.Port)
	if err := http.ListenAndServe(httpListenAddr, nil); err != nil {
		log.Fatalf("Could not start HTTP server listening: %s\n", err)
	}
}

func DontCache(w *http.ResponseWriter) {
	(*w).Header().Set("Cache-Control", "no-cache, no-store, must-revalidate") // HTTP 1.1
	(*w).Header().Set("Pragma", "no-cache")                                   // HTTP 1.0
	(*w).Header().Set("Expires", "0")                                         // Proxies
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "./index.html")
}

func TestHandler(w http.ResponseWriter, r *http.Request) {
	// Set a fresh session ID, overwriting any session ID stored in the sessid
	// cookie from a previous execution that might not have expired yet
	store.New(w, r)

	http.ServeFile(w, r, "./test.html")
}

