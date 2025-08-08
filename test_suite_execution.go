package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"html"
	"html/template"
	"log"
	"net"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/lib/pq"
)

type SuiteExecutionHierarchyRow struct {
	Type         string         `db:"type"`
	Id           int            `db:"id"`
	IdPath       NullIntSlice   `db:"id_path"`
	Title        string         `db:"title"`
	Description  sql.NullString `db:"description"`
	Behaviour    sql.NullString `db:"behaviour"`
	Live         sql.NullBool   `db:"live"`
	TestFunction sql.NullString `db:"test_function"`
	Timeout      sql.NullInt64  `db:"timeout"`
	Parent       sql.NullInt64  `db:"parent"`
	OutcomeTotal NullIntSlice   `db:"outcome_total"`
	Outcome      sql.NullString `db:"outcome"`
	Reason       sql.NullString `db:"reason"`
	Duration     sql.NullInt64  `db:"duration"`
}

type TestResult struct {
	Outcome  string `json:"outcome"` // one of {"pass", "warning", "critical", "skip"}
	Reason   string `json:"reason"`
	Duration int    `json:"duration"`
}

type SuiteExecution struct {
	Id                  int                   `json:"id"`
	Passkey             string                `json:"passkey"`
	Timestamp           time.Time             `json:"timestamp"`
	UserAgent           string                `json:"userAgent"`
	IP                  string                `json:"ip"`
	BrowserAuditVersion string                `json:"browserAuditVersion"`
	Settings            map[string]string     `json:"settings"`
	TestResults         map[string]TestResult `json:"testResults"`
}

func ResultsPageHandler(w http.ResponseWriter, r *http.Request) {
	v := struct {
		Id      string
		Passkey string
	}{
		mux.Vars(r)["id"],
		mux.Vars(r)["passkey"],
	}

	t, err := template.ParseFiles("./results.html")
	if err != nil {
		log.Panic(err)
	}
	t.Execute(w, v)
}

func GetSuiteExecutionHandler(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]
	passkey := mux.Vars(r)["passkey"]

	DontCache(&w)
	w.Header().Set("Content-Type", "text/javascript")

	// Recover metadata for this suite execution
	row, err := db.Query("SELECT * FROM suite_execution_metadata($1, $2)", id, passkey)

	if err, ok := err.(*pq.Error); ok {
		// If the given test suite execution ID doesn't exist, or if the given
		// passkey is incorrect for this test suite execution, output some
		// JavaScript that shows the error message and hides the other (now
		// irrelevant) UI objects
		if err.Code.Class() == "22" && (err.Column == "id" || err.Column == "passkey") {
			fmt.Fprintln(w, "browserAuditUI.notificationBar.hide();\n")
			fmt.Fprintln(w, "browserAuditUI.scoreboard.hide();\n")
			fmt.Fprintln(w, "browserAuditUI.executionInfoPanel.hide();\n")
			fmt.Fprintln(w, "browserAuditUI.testReportList.hide();\n")
			fmt.Fprintln(w, "$('#scoreboard-denied').removeClass('hide');\n")

			log.Printf("Couldn't find metadata for test suite execution ID %s with passkey %s: %s\n", id, passkey, err)
			return
		} else {
			// Otherwise, something unanticipated happened: panic
			log.Panic(err)
		}
	}

	defer row.Close()

	// Extract metadata from the result row to populate the execution
	// information panel in the BrowserAudit UI
	var timestampISO8601, ip, userAgent string
	row.Next()
	if err := row.Scan(&timestampISO8601, &ip, &userAgent); err != nil {
		log.Panic(err)
	}

	// Look up the hostname(s) associated with the IP address used during
	// this test suite execution
	var hostname string
	if hostnames, err := net.LookupAddr(ip); err == nil {
		hostname = "\"(" + strings.Join(hostnames, ", ") + ")\""
	} else {
		hostname = "null"
	}

	// Look up the ISO 3166-1 alpha-2 country code associated with this IP
	// address in the GeoIP2 database
	var country string
	if geoipRecord, err := geoipDB.Country(net.ParseIP(ip)); err == nil {
		country = fmt.Sprintf("[ [\"/static/img/flags-iso/flat/16/%s.png\", \"%s\"] ]", geoipRecord.Country.IsoCode, geoipRecord.Country.Names["en"])
	} else {
		country = "null"
	}

	fmt.Fprintln(w, "(function() {")

	fmt.Fprintf(w,
		"  browserAuditUI.executionInfoPanel.addInfo(\"Test date & time\", new Date(\"%s\").toString(), \"(<time class=\\\"ago\\\" datetime=\\\"%s\\\"></time>)\", null, null);\n",
		timestampISO8601, timestampISO8601)

	fmt.Fprintf(w,
		"  browserAuditUI.executionInfoPanel.addInfo(\"IP address\", \"%s\", %s, %s, \"This was the IP address being used by the web browser at the time the test suite was run. It is not necessarily the same as the IP address being used to view this results page.\");\n",
		ip, hostname, country)

	fmt.Fprintf(w,
		"  browserAuditUI.executionInfoPanel.addInfo(\"Browser identifier\", \"<tt class=\\\"useragent\\\">%s</tt>\", null, null, \"This was the <code>User-Agent</code> string reported by the web browser at the time the test suite was run. It is not guaranteed to be accurate, particularly if privacy extensions were installed in the browser.\");\n",
		html.EscapeString(userAgent))

	fmt.Fprintf(w,
		"  $.ua.set(he.decode(\"%s\"));\n",
		html.EscapeString(userAgent))

	fmt.Fprintln(w, "  $(document).ready(browserAuditUI.executionInfoPanel.ready);")

	// Get the test suite hierarchy for this execution
	hierarchy, err := db.Queryx("SELECT * FROM test_suite_execution_hierarchy($1)", id)
	if err != nil {
		log.Panic(err)
	}
	defer hierarchy.Close()

	// The JavaScript variables f and t will be used to temporarily store
	// references to test functions and test UI objects respectively
	fmt.Fprintln(w, "  var f, t;")

	hierRow := SuiteExecutionHierarchyRow{}

	// The first row in the resulting table is the "meta-row" defining the
	// overall outcome totals for this suite execution, which are used to set
	// the values in the scoreboard in the BrowserAudit UI
	if hierarchy.Next() {
		if err := hierarchy.StructScan(&hierRow); err != nil {
			log.Panic(err)
		}

		fmt.Fprintf(w, "  browserAuditUI.scoreboard.setTotal(%d);\n", hierRow.OutcomeTotal.IntSlice[0]+hierRow.OutcomeTotal.IntSlice[1]+hierRow.OutcomeTotal.IntSlice[2]+hierRow.OutcomeTotal.IntSlice[3])
		fmt.Fprintf(w, "  browserAuditUI.scoreboard.setOutcome('pass', %d);\n", hierRow.OutcomeTotal.IntSlice[0])
		fmt.Fprintf(w, "  browserAuditUI.scoreboard.setOutcome('warning', %d);\n", hierRow.OutcomeTotal.IntSlice[1])
		fmt.Fprintf(w, "  browserAuditUI.scoreboard.setOutcome('critical', %d);\n", hierRow.OutcomeTotal.IntSlice[2])
		fmt.Fprintf(w, "  browserAuditUI.scoreboard.setOutcome('skip', %d);\n", hierRow.OutcomeTotal.IntSlice[3])
	}

	// The remaining rows in the resulting table represent the test suite
	// hierarchy for this suite execution: for each row in the hierarchy,
	// output JavaScript that reconstructs the BrowserAudit UI
	for hierarchy.Next() {
		if err := hierarchy.StructScan(&hierRow); err != nil {
			log.Panic(err)
		}

		// timeout and duration will be NULL for all categories, and parent will
		// be NULL for top-level categories; in these cases, make them
		// JavaScript nulls stored in strings
		var timeout, parent, duration string
		if hierRow.Timeout.Valid {
			timeout = strconv.FormatInt(hierRow.Timeout.Int64, 10)
		} else {
			timeout = "null"
		}
		if hierRow.Parent.Valid {
			parent = strconv.FormatInt(hierRow.Parent.Int64, 10)
		} else {
			parent = "null"
		}
		if hierRow.Duration.Valid {
			duration = strconv.FormatInt(hierRow.Duration.Int64, 10)
		} else {
			duration = "null"
		}

		if hierRow.Type == "c" { // row represents a category
			// Create a new UI object for this category
			fmt.Fprintf(w,
				"  var cat%d = browserAuditUI.testReportCategory(%d, \"%s\", \"%s\");\n",
				hierRow.Id, hierRow.Id, strings.Replace(hierRow.Title, "\"", "\\\"", -1), strings.Replace(hierRow.Description.String, "\"", "\\\"", -1))

			// If this category has a parent (i.e., as long as it isn't a top-
			// level category), add the UI object to its parent category UI
			// object; if it's a top-level category, add the UI object to the
			// test report list UI object
			if hierRow.Parent.Valid {
				fmt.Fprintf(w,
					"  cat%s.addChild(cat%d);\n",
					parent, hierRow.Id)
			} else {
				fmt.Fprintf(w,
					"  browserAuditUI.testReportList.addChild(cat%d);\n",
					hierRow.Id)
			}

			// If this category contains tests whose outcomes were "warning",
			// "critical" or "skip", add labels with the corresponding numbers
			// of tests with these outcomes to the category UI object
			if hierRow.OutcomeTotal.IntSlice[1] > 0 {
				fmt.Fprintf(w,
					"  cat%d.setOutcome('warning', %d);\n",
					hierRow.Id, hierRow.OutcomeTotal.IntSlice[1])
			}
			if hierRow.OutcomeTotal.IntSlice[2] > 0 {
				fmt.Fprintf(w,
					"  cat%d.setOutcome('critical', %d);\n",
					hierRow.Id, hierRow.OutcomeTotal.IntSlice[2])
			}
			if hierRow.OutcomeTotal.IntSlice[3] > 0 {
				fmt.Fprintf(w,
					"  cat%d.setOutcome('skip', %d);\n",
					hierRow.Id, hierRow.OutcomeTotal.IntSlice[3])
			}

			// If this category contains only tests that passed, collapse the
			// category UI object
			if hierRow.OutcomeTotal.IntSlice[1] == 0 && hierRow.OutcomeTotal.IntSlice[2] == 0 && hierRow.OutcomeTotal.IntSlice[3] == 0 {
				fmt.Fprintf(w,
					"  cat%d.setCollapsed(true);\n",
					hierRow.Id)
			}
		} else { // hierRow.Type == "t": row represents a test
			fmt.Fprintf(w,
				"  f = %s;\n",
				hierRow.TestFunction.String)

			fmt.Fprintf(w,
				"  t = browserAuditUI.testReport(%d, \"%s\", \"%s\", %s, f, f.reportData);\n",
				hierRow.Id, strings.Replace(hierRow.Title, "\"", "\\\"", -1), hierRow.Behaviour.String, timeout)

			fmt.Fprintf(w,
				"  cat%s.addChild(t);\n",
				parent)

			fmt.Fprintf(w,
				"  t.setResult(\"%s\", \"%s\", %s);\n",
				hierRow.Outcome.String, html.EscapeString(hierRow.Reason.String), duration)
		}
	}

	if err := hierarchy.Err(); err != nil {
		log.Panic(err)
	}

	fmt.Fprintln(w, "  browserAuditUI.notificationBar.hide();")
	fmt.Fprintln(w, "})();")
}

func PutSuiteExecutionHandler(w http.ResponseWriter, r *http.Request) {
	// Parse the JSON-encoded suite execution data in the request body
	decoder := json.NewDecoder(r.Body)
	var execution SuiteExecution
	err := decoder.Decode(&execution)
	if err != nil {
		log.Printf("Error deserialising test suite execution JSON string: %s\n", err)
		http.Error(w, "Invalid test suite execution JSON object", http.StatusBadRequest)
		return
	}

	// Add the user agent, IP address and BrowserAudit version to the struct
	execution.UserAgent = r.UserAgent()
	execution.IP = RequestIP(r).String()
	execution.BrowserAuditVersion = Version()

	tx, err := db.Beginx()
	if err != nil {
		log.Panic(err)
	}

	// Insert the suite execution summary data into the database; this assigns a
	// suite execution ID and passkey for this submission, which we will use and
	// return later
	err = tx.QueryRowx(
		`INSERT INTO suite_execution (user_agent, ip, browseraudit_version) VALUES ($1, $2, $3) RETURNING id, passkey`,
		execution.UserAgent,
		execution.IP,
		execution.BrowserAuditVersion,
	).Scan(&execution.Id, &execution.Passkey)
	if err != nil {
		tx.Rollback()
		log.Panic(err)
	}

	// Insert the settings used for this suite execution into the database
	for settingKey, settingValue := range execution.Settings {
		_, err = tx.Exec(
			`INSERT INTO suite_execution_setting (id, key, value) VALUES ($1, $2, $3)`,
			execution.Id,
			settingKey,
			settingValue,
		)

		if err, ok := err.(*pq.Error); ok {
			tx.Rollback()

			// Check whether the key/value pair violated an integrity constraint
			var baErr error
			if err.Code.Class() == "23" && err.Constraint == "valid_pair" {
				baErr = fmt.Errorf("Invalid setting key/value pair: %s => %s", settingKey, settingValue)
			}

			if baErr != nil {
				// If this is an error we've anticipated, return HTTP 400 and
				// log the error message
				log.Printf("Error recording test results: %s\n", baErr)
				http.Error(w, baErr.Error(), http.StatusBadRequest)
				return
			} else {
				// Otherwise, something unanticipated happened: panic
				log.Panic(err)
			}
		}
	}

	// Insert each of the test results for this suite execution into the
	// database
	for testId, testResult := range execution.TestResults {
		_, err = tx.Exec(
			`INSERT INTO suite_execution_test (id, test_id, outcome, reason, duration) VALUES ($1, $2, $3, $4, $5)`,
			execution.Id,
			testId,
			testResult.Outcome,
			testResult.Reason,
			testResult.Duration,
		)

		if err, ok := err.(*pq.Error); ok {
			//fmt.Printf("Code=%#v DataTypeName=%#v Column=%#v Constraint=%#v\n", err.Code, err.DataTypeName, err.Column, err.Constraint)
			tx.Rollback()

			// Check whether any fields violated a type or integrity constraint
			var baErr error
			if err.Code == "22P02" && regexp.MustCompile(".*?integer:").MatchString(err.Message) {
				baErr = fmt.Errorf("Invalid test ID: %s", testId)
			} else if err.Code.Class() == "23" && err.Constraint == "test_id_fkey" {
				baErr = fmt.Errorf("Nonexistent test ID: %s", testId)
			} else if err.Code.Class() == "23" && err.Constraint == "test_id_live" {
				baErr = fmt.Errorf("Non-live test ID: %s", testId)
			} else if err.Code == "22P02" && regexp.MustCompile(".*?test_outcome:").MatchString(err.Message) {
				baErr = fmt.Errorf("Error in result for test ID %s: invalid test outcome %s", testId, testResult.Outcome)
			} else if err.Code.Class() == "23" && err.Constraint == "duration_nonnegative" {
				baErr = fmt.Errorf("Error in result for test ID %s: %d is a negative duration", testId, testResult.Duration)
			}

			if baErr != nil {
				// If this is an error we've anticipated, return HTTP 400 and
				// log the error message
				log.Printf("Error recording test results: %s\n", baErr)
				http.Error(w, baErr.Error(), http.StatusBadRequest)
				return
			} else {
				// Otherwise, something unanticipated happened: panic
				log.Panic(err)
			}
		}
	}

	// Commit insertions into the database
	err = tx.Commit()
	if err != nil {
		log.Panic(err)
	}

	// Return the suite execution ID and passkey assigned to this submission
	fmt.Fprintf(w, "%d %s", execution.Id, execution.Passkey)
}
