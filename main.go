package main

import (
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"log"
	"net"
	"net/http"
	"os/exec"
	"strings"

	"github.com/go-playground/validator"
	"github.com/gorilla/mux"
	"github.com/jmoiron/sqlx"
	"github.com/knadh/koanf"
	"github.com/knadh/koanf/parsers/yaml"
	"github.com/knadh/koanf/providers/confmap"
	"github.com/knadh/koanf/providers/env"
	"github.com/knadh/koanf/providers/file"
	_ "github.com/lib/pq"
	"github.com/oschwald/geoip2-golang"
	"github.com/robfig/cron"
	"github.com/spf13/pflag"
)

type Config struct {
	HTTPServer struct {
		Host          string `validate:"required,hostname_rfc1123|ip"`
		Port          int    `validate:"required,gte=1,lte=65535"`
		SessionIDSalt string `validate:"required"`
		GeoIPDatabase string `validate:"required"`
	}
	Memcached struct {
		Host      string `validate:"required,hostname_rfc1123|ip"`
		Port      int    `validate:"required,gte=1,lte=65535"`
		KeyPrefix string `validate:"printascii"`
	}
	Database struct {
		Host     string `validate:"required,hostname_rfc1123|ip"`
		Port     int    `validate:"required,gte=1,lte=65535"`
		Username string `validate:"required"`
		Password string
		DB       string `validate:"required"`
		SSLMode  string
	}
}

// The BrowserAudit server version - set this at compile-time with:
//
//	go build -ldflags "-X main.version=..."
//
// Otherwise, if the server runs from a git repository, the commit hash of the
// repository's HEAD will be used; if the directory is not a git repository, the
// string "unknown" will be used
var version string = ""

var configPath string
var store *BASessionStore
var db *sqlx.DB
var geoipDB *geoip2.Reader

func main() {
	var err error // This allows us to use the global vars geoipDB and db with :=

	ParseFlags()

	cfg := LoadConfig()

	// Read GeoLite2 database from file
	if geoipDB, err = geoip2.Open(cfg.HTTPServer.GeoIPDatabase); err != nil {
		log.Fatalf("Could not read GeoIP2/GeoLite2 database file '%s': %s\n",
			cfg.HTTPServer.GeoIPDatabase, err)
	}

	// Connect to Memcached server and create a new session store backed by it
	store = NewBASessionStore(
		cfg.Memcached.Host, cfg.Memcached.Port, cfg.Memcached.KeyPrefix,
		cfg.HTTPServer.SessionIDSalt)

	r := mux.NewRouter()
	r.HandleFunc("/", HomeHandler)
	r.HandleFunc("/accessibility", AccessibilityHandler)
	r.HandleFunc("/test", TestHandler)

	r.PathPrefix("/static/").Handler(http.FileServer(http.Dir(".")))

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
	r.HandleFunc("/get_referer_policy", GetReferrerPolicyHandler)

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
	r.HandleFunc("/cors/allow-credentials/{originBase64}/{credentialsBase64}", CorsAllowCredentialsHandler)

	r.HandleFunc("/results/{id:[0-9]+}/{passkey:[0-9a-f]+}", ResultsPageHandler)
	r.HandleFunc("/suite_execution/get/{id:[0-9]+}/{passkey:[0-9a-f]+}", GetSuiteExecutionHandler)
	r.HandleFunc("/suite_execution/put", PutSuiteExecutionHandler)

	r.HandleFunc("/redirect/{dest}", RedirectHandler)

	r.HandleFunc("/analytics", AnalysisHandler)
	r.HandleFunc("/analytics/catDuration", AnalysisDurationHandler)
	r.HandleFunc("/analytics/subcatTopFail", AnalysisTopFailingSubCategoriesHandler)
	r.HandleFunc("/analytics/displayModePercentages", AnalysisDisplayModePercentagesHandler)
	r.HandleFunc("/analytics/topUserAgents", AnalysisTopUserAgentsHandler)
	r.HandleFunc("/analytics/catFailRatio", AnalysisCategoriesFailRatioHandler)
	r.HandleFunc("/analytics/catSkipRatio", AnalysisCategoriesSkipRatioHandler)
	r.HandleFunc("/analytics/topUserAgentFailRatio", AnalysisTopUserAgentFailRatioHandler)
	r.HandleFunc("/analytics/monthlyExecutions", AnalysisMonthlyExecutionsHandler)
	r.HandleFunc("/analytics/monthlyFails", AnalysisMonthlyFailsHandler)
	r.HandleFunc("/analytics/totalTests", AnalysisTotalTestsHandler)
	r.HandleFunc("/analytics/totalTestsExecuted", AnalysisTotalTestsExecutedHandler)
	r.HandleFunc("/analytics/uniqueUserAgents", AnalysisUniqueUserAgentsHandler)
	r.HandleFunc("/analytics/lastMonthTests", AnalysisLastMonthTestsHandler)
	r.HandleFunc("/analytics/lastMonthTestsExecuted", AnalysisLastMonthTestsExecutedHandler)
	r.HandleFunc("/analytics/lastMonthUniqueUserAgents", AnalysisLastMonthUniqueUserAgentsHandler)

	// Connect to the database server
	var dbDataSource = fmt.Sprintf("host=%s port=%d user='%s' password='%s' dbname='%s' sslmode='%s'",
		cfg.Database.Host, cfg.Database.Port,
		strings.Replace(cfg.Database.Username, "'", "\\'", -1),
		strings.Replace(cfg.Database.Password, "'", "\\'", -1),
		strings.Replace(cfg.Database.DB, "'", "\\'", -1),
		cfg.Database.SSLMode,
	)

	if db, err = sqlx.Connect("postgres", dbDataSource); err != nil {
		log.Fatalf("Could not connect to database server: %s\n", err)
	}

	// Start cron scheduler in separate go routine
	go ScheduleQueryJobs()

	// Start listening on the given IP address and port
	http.Handle("/", r)
	var httpListenAddr = fmt.Sprintf("%s:%d",
		cfg.HTTPServer.Host, cfg.HTTPServer.Port)
	if err := http.ListenAndServe(httpListenAddr, nil); err != nil {
		log.Fatalf("Could not start HTTP server listening: %s\n", err)
	}
}

func Version() string {
	// If a version string wasn't supplied at compile-time (i.e. with
	// -ldflags "-X main.version=..."), assume the current directory is a
	// git repository and attempt to recover HEAD's commit hash
	if version == "" {
		commitHash, err := exec.Command("git", "rev-parse", "HEAD").Output()

		if err == nil {
			log.Println("successfully recovered commit hash from git")
			version = string(commitHash)[:40] // trim newline at end of hash
		} else {
			// We couldn't recover a version string
			version = "unknown"
		}
	}

	return version
}

func ParseFlags() {
	pflag.StringVarP(&configPath, "config", "c", "server.yaml", "path to configuration file")

	pflag.Parse()
}

func LoadConfig() *Config {
	envPrefix := "BROWSERAUDIT_"

	k := koanf.New(".")

	// Defaults:
	k.Load(confmap.Provider(map[string]interface{}{
		"httpserver.host":          "127.0.0.1",
		"httpserver.port":          8080,
		"httpserver.geoipdatabase": "GeoLite2-Country.mmdb",
		"memcached.host":           "127.0.0.1",
		"memcached.port":           11211,
		"memcached.keyprefix":      "browseraudit",
		"database.host":            "127.0.0.1",
		"database.port":            5432,
	}, "."), nil)

	// Override using configuration file:
	if err := k.Load(file.Provider(configPath), yaml.Parser()); err != nil {
		log.Printf("Could not read server configuration file '%s': %s\n", configPath, err)
	}

	// Override using environment variables:
	k.Load(env.Provider(envPrefix, ".", func(s string) string {
		return strings.Replace(strings.ToLower(strings.TrimPrefix(s, envPrefix)), "_", ".", -1)
	}), nil)

	var config *Config
	k.Unmarshal("", &config)

	// Generate a cryptographically-secure session ID salt if one wasn't
	// configured (this isn't set as a default above to avoid unnecessarily
	// draining the entropy pool)
	if config.HTTPServer.SessionIDSalt == "" {
		salt, err := GenerateSessionIDSalt()
		if err != nil {
			log.Fatalf("Failed to generate session ID salt: %v\n", err)
		}

		config.HTTPServer.SessionIDSalt = salt
		log.Println("No session ID salt configured; using a randomly-generated one")
	}

	validate := validator.New()
	if err := validate.Struct(config); err != nil {
		for _, err := range err.(validator.ValidationErrors) {
			log.Printf("Invalid value for setting '%s'\n", err.Namespace())
		}

		log.Fatalln("Server configuration failed validation")
	}

	return config
}

func GenerateSessionIDSalt() (string, error) {
	const length = 32

	buf := make([]byte, length)
	_, err := rand.Read(buf)
	if err != nil {
		return "", err
	}

	return base64.URLEncoding.EncodeToString(buf), nil
}

func DontCache(w *http.ResponseWriter) {
	(*w).Header().Set("Cache-Control", "no-cache, no-store, must-revalidate") // HTTP 1.1
	(*w).Header().Set("Pragma", "no-cache")                                   // HTTP 1.0
	(*w).Header().Set("Expires", "0")                                         // Proxies
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "./index.html")
}

func AccessibilityHandler(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "accessibility.html")
}

func TestHandler(w http.ResponseWriter, r *http.Request) {
	// Set a fresh session ID, overwriting any session ID stored in the sessid
	// cookie from a previous execution that might not have expired yet
	store.New(w, r)

	http.ServeFile(w, r, "./test.html")
}

func RequestIP(r *http.Request) net.IP {
	var ip string

	// Use the first IP address in the X-Forwarded-For header in the request
	// (this is usually injected by an upstream proxying server, and will
	// contain the IP address of the originating client followed by the IP
	// address of every proxying server that the request has passed through
	// on the way, delimited with commas)
	if len(r.Header["X-Forwarded-For"]) != 0 {
		ip = strings.Split(r.Header["X-Forwarded-For"][0], ",")[0]
		// Otherwise, assume that there are no proxies between this server and
		// the client, and that the client is at the other end of this TCP
		// connection
	} else {
		ip = strings.Split(r.RemoteAddr, ":")[0]
	}

	return net.ParseIP(ip)
}

func RequestScheme(r *http.Request) string {
	// Use the value of the X-Forwarded-Proto header in the request (this is
	// usually injected by an upstream proxying server, and will contain the
	// scheme originally used to send the request to the proxying server;
	// this should be set to "http" or "https" as appropriate)
	if len(r.Header["X-Forwarded-Proto"]) != 0 {
		return r.Header["X-Forwarded-Proto"][0]
		// Otherwise, assume the scheme was "http", since this server isn't
		// capable of terminating TLS connections: that would have to be done by
		// an upstream proxying server, which would be expected to inject an
		// X-Forwarded-Proto header into the request
	} else {
		return "http"
	}
}

func RequestHost(r *http.Request) string {
	// Use the value of the X-Forwarded-Host header in the request (this
	// is usually injected by an upstream proxying server, and will contain
	// the value of the Host header as sent to the proxying server)
	if len(r.Header["X-Forwarded-Host"]) != 0 {
		return r.Header["X-Forwarded-Host"][0]
		// Otherwise, use the value of the Host header in the request
	} else {
		return r.Header.Get("Host")
	}
}

// Go subroutine for the cron scheduler which runs heavy queries daily for analysis
func ScheduleQueryJobs() {
	// Create a new cron scheduler
	c := cron.New()

	c.AddFunc("0 0 3 * * *", ScheduledTopFailingSubCategoriesHandler)
	c.AddFunc("0 0 6 * * *", ScheduledCategoriesFailRatioHandler)
	c.AddFunc("0 0 9 * * *", ScheduledCategoriesSkipRatioHandler)
	c.AddFunc("0 0 12 * * *", ScheduledTopUserAgentFailRatioHandler)
	c.AddFunc("0 0 15 * * *", ScheduledMonthlyFailsHandler)

	// Start the cron scheduler
	c.Start()
	log.Println("Started cron scheduler")

	// Keep the script running
	select {}
}
