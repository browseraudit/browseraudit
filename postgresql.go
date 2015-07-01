package main

// PostgreSQL-specific library functions

import (
	"database/sql/driver"
	"errors"
	"strconv"
	"strings"
)

type IntSlice []int

type NullIntSlice struct {
	IntSlice IntSlice
	Valid    bool     // true if IntSlice is not NULL
}

// Scans a Postgres integer array into an IntSlice
// http://nerglish.tumblr.com/post/90671946112/reading-arrays-from-postgres-in-golang
func (s *IntSlice) Scan(src interface{}) error {
	asBytes, ok := src.([]byte)
	if !ok {
		return error(errors.New("Scan source was not []byte"))
	}
	asString := string(asBytes)
	(*s) = strToIntSlice(asString)
	return nil
}

// Converts a string representing a Postgres integer array into an IntSlice
// http://nerglish.tumblr.com/post/90671946112/reading-arrays-from-postgres-in-golang
func strToIntSlice(s string) []int {
	r := strings.Trim(s, "{}")
	a := make([]int, 0, 10)
	for _, t := range strings.Split(r, ",") {
		i,_ := strconv.Atoi(t)
		a = append(a, i)
	}
	return a
}

func (n *NullIntSlice) Scan(value interface{}) error {
	asBytes, ok := value.([]byte)
	if !ok {
		n.IntSlice, n.Valid = make([]int, 0), false
		return nil
	}
	asString := string(asBytes)
	n.IntSlice, n.Valid = strToIntSlice(asString), true
	return nil
}

func (n NullIntSlice) Value() (driver.Value, error) {
	if !n.Valid {
		return nil, nil
	}
	return n.IntSlice, nil
}
