package main

import (
	"crypto/rand"
	"crypto/sha1"
	"fmt"
	"net/http"
	//"log"
	"regexp"
	"strconv"
	"time"

	"github.com/bradfitz/gomemcache/memcache"
	"github.com/gorilla/mux"
)

const SESSION_ID_COOKIE_NAME = "sessid"
const SESSION_ID_COOKIE_DOMAIN = ".browseraudit.com"

// =============================================================================
// BASessionStore
// =============================================================================

type BASessionStore struct {
	MemcachedClient *memcache.Client
	KeyPrefix       string
	sessionIDSalt   string
}

// Creates a new BASessionStore, backed by a Memcached server running on the
// given host and listening on the given port number
func NewBASessionStore(
	memcachedHost string, memcachedPort int, memcachedKeyPrefix string,
	sessionIDSalt string,
) *BASessionStore {
	client := memcache.New(memcachedHost + ":" + strconv.Itoa(memcachedPort))

	return &BASessionStore{
		MemcachedClient: client,
		KeyPrefix:       memcachedKeyPrefix,
		sessionIDSalt:   sessionIDSalt,
	}
}

// Creates a new session
func (store *BASessionStore) New(w http.ResponseWriter, r *http.Request) *BASession {

	random := make([]byte, 16)
	rand.Read(random)
	currentTime := strconv.FormatInt(time.Now().UnixNano(), 10)
	ip := RequestIP(r).String()
	userAgent := r.UserAgent()

	plaintext := []byte(store.sessionIDSalt + "|" + fmt.Sprintf("%x", string(random[:])) + "|" + currentTime + "|" + ip + "|" + userAgent)
	sessionID := fmt.Sprintf("%x", sha1.Sum(plaintext))

	//log.Printf("BASessionStore New(): generated session ID: %s", sessionID)

	cookie := &http.Cookie{
		Name:    SESSION_ID_COOKIE_NAME,
		Value:   sessionID,
		Domain:  SESSION_ID_COOKIE_DOMAIN,
		Path:    "/",
		Expires: time.Now().Add(24 * time.Hour),
	}
	http.SetCookie(w, cookie)

	return &BASession{
		MemcachedClient: store.MemcachedClient,
		KeyPrefix:       store.KeyPrefix,
		Id:              sessionID,
	}
}

// Loads a session based on the session ID in the Cookie HTTP header or URL
// query string, or creates a new session if neither exists
func (store *BASessionStore) Get(w http.ResponseWriter, r *http.Request) *BASession {
	// Find the session ID:
	var sessionID string
	// - #1: look at the value of the "sessid" cookie in the Cookie HTTP header
	if c, err := r.Cookie(SESSION_ID_COOKIE_NAME); err == nil && regexp.MustCompile("^[0-9a-f]{40}").MatchString(c.Value) {
		sessionID = c.Value
		//log.Printf("BASessionStore Get(): got session ID from cookie: %s", sessionID)
		// - #2: look at the value of the "sessid" key in the URL query string
	} else if r.ParseForm(); r.Form[SESSION_ID_COOKIE_NAME] != nil && regexp.MustCompile("^[0-9a-f]{40}").MatchString(r.Form.Get(SESSION_ID_COOKIE_NAME)) {
		sessionID = r.Form.Get(SESSION_ID_COOKIE_NAME)
		//log.Printf("BASessionStore Get(): got session ID from query string: %s", sessionID)
		// - Otherwise, no session ID was sent with this request: generate a new one
		//   based on the session ID salt in server.cfg, the remote IP and user agent
		//   string, and set it as the value of the "sessid" cookie
	} else {
		newSession := store.New(w, r)
		//log.Printf("BASessionStore Get(): no session ID found, set new: %s", newSession.Id)
		return newSession
	}

	return &BASession{
		MemcachedClient: store.MemcachedClient,
		KeyPrefix:       store.KeyPrefix,
		Id:              sessionID,
	}
}

// =============================================================================
// BASession
// =============================================================================

type BASession struct {
	MemcachedClient *memcache.Client
	KeyPrefix       string
	Id              string
}

// Gets the value associated with the given key for this session; reading this
// value also implicitly deletes the key
func (session *BASession) Get(key string) (string, error) {
	item, err := session.MemcachedClient.Get(session.KeyPrefix + "|" + session.Id + "|" + key)
	if err != nil {
		//log.Printf("BASession Get(): %s: error getting '%s': %s", session.Id, key, err)
		return "", err
	}

	value := string(item.Value[:])
	//log.Printf("BASession Get(): %s: value of key '%s' is '%s'", session.Id, key, value)
	session.Delete(key)
	return value, nil
}

// Sets the value associated with the given key for this session
func (session *BASession) Set(key string, value string) error {
	item := memcache.Item{
		Key:        session.KeyPrefix + "|" + session.Id + "|" + key,
		Value:      []byte(value),
		Expiration: 30,
	}

	if err := session.MemcachedClient.Set(&item); err != nil {
		//log.Printf("BASession Set(): %s: error setting '%s': %s", session.Id, key, err)
		return err
	}

	//log.Printf("BASession Set(): %s: value of key '%s' set to '%s'", session.Id, key, value)
	return nil
}

// Deletes the value associated with the given key for this session
func (session *BASession) Delete(key string) error {
	if err := session.MemcachedClient.Delete(session.KeyPrefix + "|" + session.Id + "|" + key); err != nil {
		//log.Printf("BASession Delete(): %s: error deleting '%s': '%s'", session.Id, key, err)
		return err
	}

	//log.Printf("BASession Delete(): %s: deleted key '%s'", session.Id, key)
	return nil
}

// =============================================================================
// Miscellaneous functions
// =============================================================================

func SetSessionIDCookieHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	cookie := &http.Cookie{
		Name:    SESSION_ID_COOKIE_NAME,
		Value:   mux.Vars(r)["sessionID"],
		Domain:  RequestHost(r),
		Path:    "/",
		Expires: time.Now().Add(24 * time.Hour),
	}

	http.SetCookie(w, cookie)
	http.ServeFile(w, r, "./static/pixel.png")
}
