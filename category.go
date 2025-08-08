package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
)

type CategoryRow struct {
	Id          int            `db:"id"`
	Title       string         `db:"title"`
	Description sql.NullString `db:"short_description"`
	Default     bool           `db:"in_default"`
	Parent      sql.NullInt64
}

func JSONCategoryTreeHandler(w http.ResponseWriter, r *http.Request) {
	DontCache(&w)
	w.Header().Set("Content-Type", "text/javascript")
	fmt.Fprintln(w, "(function() {")

	// Get the live category list from the category table --- this is sorted by
	// the order in which the categories are to be displayed
	// Suggestion for using WITH RECURSIVE courtesy of:
	// http://blog.timothyandrew.net/blog/2013/06/24/recursive-postgres-queries/
	// (note: WITH RECURSIVE is Postgres-specific)
	hierarchy, err := db.Queryx(`
		WITH RECURSIVE hierarchy AS (
			SELECT id, title, short_description, in_default, parent, array[execute_order] AS execute_order
			FROM category
			WHERE parent IS NULL AND live = true
			UNION
			SELECT c.id, c.title, c.short_description, c.in_default, c.parent, (hierarchy.execute_order || c.execute_order)
			FROM hierarchy, category c
			WHERE c.parent = hierarchy.id AND c.live = true
		)
		SELECT id, title, short_description, in_default, parent
		FROM hierarchy
		ORDER BY execute_order`)

	if err != nil {
		log.Panic(err)
	}

	defer hierarchy.Close()

	// Each row represents one category in the category hierarchy
	cat := CategoryRow{}
	for hierarchy.Next() {
		if err := hierarchy.StructScan(&cat); err != nil {
			log.Panic(err)
		}

		var description, parent string
		if cat.Description.Valid {
			description = "\"" + strings.Replace(cat.Description.String, "\"", "\\\"", -1) + "\""
		} else {
			description = "null"
		}
		if cat.Parent.Valid {
			parent = strconv.FormatInt(cat.Parent.Int64, 10)
		} else {
			parent = "null"
		}

		fmt.Fprintf(w,
			"  browserAuditUI.categorySelectionPanel.add(%d, \"%s\", %s, %s, %t);\n",
			cat.Id,
			strings.Replace(cat.Title, "\"", "\\\"", -1),
			description,
			parent,
			cat.Default)
	}

	if err := hierarchy.Err(); err != nil {
		log.Panic(err)
	}

	fmt.Fprintln(w, "  browserAuditUI.categorySelectionPanel.hierarchicalise();")
	fmt.Fprintln(w, "})();")
}
