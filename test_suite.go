package main

import (
	"database/sql"
	"fmt"
	"github.com/gorilla/mux"
	"log"
	"net/http"
	"regexp"
	"strconv"
	"strings"
)

func GenerateTestSuiteHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)

	// Generate a test suite based on the category IDs given by the user: of the
	// category IDs that are live and have a route back to the "root" of the
	// test suite hierarchy based on the category IDs given, this generates the
	// JavaScript code necessary to add the categories and tests to the test
	// framework running in the user's browser

	// Sanity-check for given category IDs: it must be a comma-delimited list of
	// integers, or * (which denotes all live categories in the category table)
	categoryIDs := mux.Vars(r)["catids"]
	if categoryIDs == "*" {
		// It's enough just to find the top-level categories here: the recursive
		// query we run below will find all of the live child categories we also
		// need to include in the test suite execution
		if err := db.QueryRow("SELECT '{' || array_to_string(array_agg(id),',') || '}' AS categories FROM category WHERE parent IS NULL AND live = true").Scan(&categoryIDs); err != nil {
			log.Panicf("Unable to get list of top-level categories: %s\n", err)
		}
	} else if regexp.MustCompile("^[0-9]+(,[0-9]+)*$").MatchString(categoryIDs) {
		categoryIDs = "{" + categoryIDs + "}"
	} else {
		log.Panic("Malformed category IDs supplied")
	}

	w.Header().Set("Content-Type", "text/javascript")
	fmt.Fprintln(w, "// Automatically-generated BrowserAudit test suite\n")
	
	// The table returned by this query is sorted by the order in which the
	// categories and then tests are to be executed; the hierarchy is correct by
	// the time it gets here, and so can be printed line-by-line with no further
	// processing of the resulting table
	
	// Suggestion for using WITH RECURSIVE courtesy of:
	// http://blog.timothyandrew.net/blog/2013/06/24/recursive-postgres-queries/
	// (note: WITH RECURSIVE is Postgres-specific)
	rows, err := db.Query(`
		WITH RECURSIVE touched_parent_categories AS (
			SELECT unnest($1::int[]) AS id
			UNION
			SELECT category.parent AS id FROM category, touched_parent_categories tpc WHERE tpc.id = category.id AND category.parent IS NOT NULL
		), touched_child_categories AS (
			SELECT unnest($1::int[]) AS id
			UNION
			SELECT category.id FROM category, touched_child_categories tcc WHERE category.parent = tcc.id
		), touched_categories AS (
			SELECT id FROM touched_parent_categories
			UNION
			SELECT id FROM touched_child_categories
		), hierarchy AS (
			(
				SELECT 'c' as type, id, title, description, NULL::test_behaviour AS behaviour, NULL::varchar AS test_function, NULL::smallint AS timeout, parent, array[execute_order] AS execute_order
				FROM category
				WHERE parent IS NULL AND live = true AND id IN (SELECT id FROM touched_categories)
			) UNION (
				SELECT e.type, e.id, e.title, e.description, e.behaviour, e.test_function, e.timeout, e.parent, (h.execute_order || e.execute_order)
				FROM (
					SELECT 't' as type, id, title, NULL::varchar AS description, behaviour, test_function, timeout, parent, execute_order
					FROM test
					WHERE live = true AND parent IN (SELECT id FROM touched_categories)
					UNION
					SELECT 'c' as type, id, title, description, NULL::test_behaviour AS behaviour, NULL::varchar AS test_function, NULL::smallint AS timeout, parent, execute_order
					FROM category
					WHERE live = true AND id IN (SELECT id FROM touched_categories)
				) e, hierarchy h
				WHERE e.parent = h.id AND h.type = 'c'
			)
		)
		SELECT type, id, title, description, behaviour, test_function, timeout, parent FROM hierarchy ORDER BY execute_order`, categoryIDs)

	if err != nil {
		log.Fatal(err)
	}

	for rows.Next() {
		var rowType string
		var id int
		var title string
		var description sql.NullString
		var behaviour sql.NullString
		var testFunctionInvocation sql.NullString
		var timeoutNullable sql.NullInt64
		var parentNullable sql.NullInt64

		// NULL description -> empty string (only the case for categories, which
		// doesn't matter because they aren't written out for categories in the
		// JavaScript below)
		description.String = ""

		// NULL behaviour -> empty string (only the case for categories, which
		// doesn't matter because they aren't written out for categories in the
		// JavaScript below)
		behaviour.String = ""

		// NULL test_function -> empty string (only the case for
		// categories, which doesn't matter because they aren't written out for
		// categories in the JavaScript below)
		testFunctionInvocation.String = ""

		if err := rows.Scan(&rowType, &id, &title, &description, &behaviour, &testFunctionInvocation, &timeoutNullable, &parentNullable); err != nil {
			log.Fatal(err)
		}

		// NULL timeout -> JavaScript null in string
		var timeout string
		if timeoutNullable.Valid {
			timeout = strconv.FormatInt(timeoutNullable.Int64, 10)
		} else {
			timeout = "null"
		}

		// NULL parent -> JavaScript null in string (only the case for top-level
		// categories)
		var parent string
		if parentNullable.Valid {
			parent = strconv.FormatInt(parentNullable.Int64, 10)
		} else {
			parent = "null"
		}

		if (rowType == "c") { // row represents a category
			fmt.Fprintf(
				w,
				"\nbrowserAuditTestFramework.addCategory(%d, %s, \"%s\", \"%s\");\n",
				id,
				parent,
				strings.Replace(title, "\"", "\\\"", -1),
				strings.Replace(description.String, "\"", "\\\"", -1))
		} else { // rowType == "t": row represents a test
			fmt.Fprintf(
				w,
				"browserAuditTestFramework.addTest(%d, %s, \"%s\", \"%s\", %s, %s);\n",
				id,
				parent,
				strings.Replace(title, "\"", "\\\"", -1),
				behaviour.String,
				timeout,
				testFunctionInvocation.String)
		}
	}

	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}
}
