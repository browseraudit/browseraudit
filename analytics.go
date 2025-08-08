package main

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/bradfitz/gomemcache/memcache"
	"time"
)

// Handler for data analysis
func AnalysisHandler(w http.ResponseWriter, r *http.Request) {
	http.ServeFile(w, r, "./analytics.html")
}

// Helper function for executing queries and returning a JSON string with the results
func ExecuteQuery(query string) (jsonData []byte, err error) {
	// Execute query
	rows, err := db.Query(query)
	if err != nil {
		log.Println(err)
		return nil, err
	}
	defer rows.Close()

	resultSet := make(map[string][]interface{})

	// Get column names
	columns, err := rows.Columns()
	if err != nil {
		log.Println(err)
		return nil, err
	}

	for rows.Next() {
		// Make a slice for the values for scanning in
		values := make([]interface{}, len(columns))
		scanArgs := make([]interface{}, len(columns))
		for i := range values {
			scanArgs[i] = &values[i]
		}

		// Scan the result into the values pointer
		if err := rows.Scan(scanArgs...); err != nil {
			log.Println(err)
			return nil, err
		}

		// Handle null values and type conversions
		for i, column := range columns {
			value := values[i]
			if value != nil {
				val := value
				switch v := value.(type) {
				case int64, int32, int16, int8, int:
					val = v.(int64)
				case float64, float32:
					val = v.(float64)
				case []byte:
					val = string(v)
				}
				resultSet[column] = append(resultSet[column], val)
			} else {
				resultSet[column] = append(resultSet[column], nil)
			}
		}
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	// Convert to JSON
	jsonData, err = json.Marshal(resultSet)
	if err != nil {
		return nil, err
	}

	return jsonData, nil
}

// Helper function for executing queries and writing the JSON response for client
func ExecuteQueryHandler(w http.ResponseWriter, query string) {
	result, err := ExecuteQuery(query)
	if err != nil {
		http.Error(w, http.StatusText(500), http.StatusInternalServerError)
	}

	// Write JSON response
	w.Header().Set("Content-type", "application/json")
	w.Write(result)
}

func ExecuteScheduledQuery(query string, queryName string) {
	jsonData, err := ExecuteQuery(query)
	if err != nil {
		log.Println(err)
		return
	}

	// Store in Memcached
	err = store.MemcachedClient.Set(&memcache.Item{
		Key:        queryName,
		Value:      jsonData,
		Expiration: 0,
	})
	if err != nil {
		log.Println(err)
	} else {
		log.Println(("Stored " + queryName + " in Memcached."))
	}
}

// Handler for retrieving results of scheduled queries from Memcached
func scheduleHandler(w http.ResponseWriter, queryName string) {
	jsonResult := ""
	memcacheResult, err := store.MemcachedClient.Get(queryName)
	if err != nil {
		jsonResult =
			`{
			"error": {
				"message": "Error retrieving data from cache"
			}
		}`
	} else {
		jsonResult = string(memcacheResult.Value)
	}

	w.Header().Set("Content-type", "application/json")
	w.Write([]byte(jsonResult))
}

func AnalysisDurationHandler(w http.ResponseWriter, r *http.Request) {
	query := `SELECT cs.title, AVG(set.duration) AS average_duration
		FROM category c
		JOIN test t ON c.id = t.parent
		JOIN suite_execution_test set ON t.parent = set.id
		JOIN category cs on cs.id = c.parent
		GROUP BY cs.title`

	ExecuteQueryHandler(w, query)
}

func AnalysisTopFailingSubCategoriesHandler(w http.ResponseWriter, r *http.Request) {
	scheduleHandler(w, "subcatTopFail")
}

func AnalysisCategoriesFailRatioHandler(w http.ResponseWriter, r *http.Request) {
	scheduleHandler(w, "catFailRatio")
}

func AnalysisCategoriesSkipRatioHandler(w http.ResponseWriter, r *http.Request) {
	scheduleHandler(w, "catSkipRatio")
}

func AnalysisTopUserAgentFailRatioHandler(w http.ResponseWriter, r *http.Request) {
	scheduleHandler(w, "topUserAgentFailRatio")
}

func AnalysisMonthlyFailsHandler(w http.ResponseWriter, r *http.Request) {
	scheduleHandler(w, "monthlyFails")
}

func ScheduledTopFailingSubCategoriesHandler() {
	query :=
		`WITH test_metrics AS (
			SELECT c.title, c.id,
						COUNT(*) FILTER (WHERE set.outcome IN ('warning', 'critical')) AS failing_test_count,
						COUNT(set.test_id) AS total_executions_count
			FROM category c
			JOIN test t ON c.id = t.parent
			JOIN suite_execution_test set ON t.id = set.test_id
			GROUP BY c.title, c.id
		)
		SELECT tm.title,
				ROUND((tm.failing_test_count::numeric / tm.total_executions_count::numeric), 3) AS failing_test_ratio
		FROM test_metrics tm
		ORDER BY failing_test_ratio DESC
		LIMIT 5`

	ExecuteScheduledQuery(query, "subcatTopFail")
}

func ScheduledCategoriesFailRatioHandler() {
	query :=
		`WITH test_metrics AS (
			SELECT c.title, c.id, c.parent,
					COUNT(*) FILTER (WHERE set.outcome IN ('warning', 'critical')) AS failing_test_count,
					COUNT(set.test_id) AS total_executions_count
			FROM category c
			JOIN test t ON c.id = t.parent
			JOIN suite_execution_test set ON t.id = set.test_id
			GROUP BY c.title, c.id, c.parent
		),
		category_metrics AS (
			SELECT c.title,
					ROUND((tm.failing_test_count::numeric / tm.total_executions_count::numeric), 3) AS failing_test_ratio
			FROM test_metrics tm
			JOIN category c ON tm.parent = c.id
		)
		SELECT title, ROUND(AVG(failing_test_ratio), 3) as averaged_fail_ratio
		FROM category_metrics
		GROUP BY title
	ORDER BY averaged_fail_ratio DESC`

	ExecuteScheduledQuery(query, "catFailRatio")
}

func ScheduledCategoriesSkipRatioHandler() {
	query :=
		`WITH test_metrics AS (
			SELECT c.title, c.id, c.parent,
					COUNT(*) FILTER (WHERE set.outcome IN ('skip')) AS skip_test_count,
					COUNT(set.test_id) AS total_executions_count
			FROM category c
			JOIN test t ON c.id = t.parent
			JOIN suite_execution_test set ON t.id = set.test_id
			GROUP BY c.title, c.id, c.parent
		),
		category_metrics AS (
			SELECT c.title,
				ROUND((tm.skip_test_count::numeric / tm.total_executions_count::numeric), 3) AS skip_test_ratio
			FROM test_metrics tm
			JOIN category c ON tm.parent = c.id
		)
		SELECT title, ROUND(AVG(skip_test_ratio), 3) as averaged_skip_ratio
		FROM category_metrics
		GROUP BY title
		ORDER by averaged_skip_ratio DESC`

	ExecuteScheduledQuery(query, "catSkipRatio")
}

func ScheduledTopUserAgentFailRatioHandler() {
	query :=
		`SELECT se.user_agent,
			COUNT(*) FILTER (WHERE set.outcome IN ('warning', 'critical'))::numeric / COUNT(*) AS failure_ratio
		FROM suite_execution_test set
		JOIN suite_execution se ON set.id = se.id
		GROUP BY se.user_agent
		HAVING COUNT(*) >= 100000
		ORDER BY failure_ratio DESC
		LIMIT 5`

	ExecuteScheduledQuery(query, "topUserAgentFailRatio")
}

func ScheduledMonthlyFailsHandler() {
	query :=
		`SELECT TO_CHAR(date_trunc('month', se.timestamp), 'Mon YYYY') AS month_year,
					COUNT(DISTINCT set.test_id) AS unique_test_count,
					COUNT(set.test_id) AS critical_test_count
		FROM suite_execution se
		JOIN suite_execution_test set ON set.id = se.id AND set.outcome = 'critical'
		GROUP BY date_trunc('month', se.timestamp)
		ORDER BY date_trunc('month', se.timestamp) ASC;`

	ExecuteScheduledQuery(query, "monthlyFails")
}

func AnalysisDisplayModePercentagesHandler(w http.ResponseWriter, r *http.Request) {
	query :=
		`SELECT value as display_mode,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM suite_execution_setting WHERE key = 'displaymode'), 3) AS percentage
		FROM suite_execution_setting
		GROUP BY value;`

	ExecuteQueryHandler(w, query)
}

func AnalysisTopUserAgentsHandler(w http.ResponseWriter, r *http.Request) {
	query :=
		`SELECT user_agent, COUNT(*) AS user_agent_count
		FROM suite_execution
		GROUP BY user_agent
		ORDER BY user_agent_count DESC
		LIMIT 5;`

	ExecuteQueryHandler(w, query)
}

func AnalysisMonthlyExecutionsHandler(w http.ResponseWriter, r *http.Request) {
	query :=
		`SELECT
		TO_CHAR(date_trunc('month', timestamp), 'Mon YYYY') AS month_year,
		COUNT(*) AS execution_count
	FROM
		suite_execution
	GROUP BY
		date_trunc('month', timestamp)
	ORDER BY
		date_trunc('month', timestamp) ASC`

	ExecuteQueryHandler(w, query)
}

func AnalysisTotalTestsHandler(w http.ResponseWriter, r *http.Request) {
	query :=
		`SELECT reltuples AS result FROM pg_class WHERE relname = 'suite_execution'`

	ExecuteQueryHandler(w, query)
}

func AnalysisTotalTestsExecutedHandler(w http.ResponseWriter, r *http.Request) {
	query :=
		`SELECT reltuples AS result FROM pg_class WHERE relname = 'suite_execution_test'`

	ExecuteQueryHandler(w, query)
}

func AnalysisUniqueUserAgentsHandler(w http.ResponseWriter, r *http.Request) {
	query :=
		`SELECT COUNT(DISTINCT user_agent) AS result
		FROM suite_execution`

	ExecuteQueryHandler(w, query)
}

func AnalysisLastMonthTestsHandler(w http.ResponseWriter, r *http.Request) {
	current := time.Now().Format("2006-01-01")
	prev := time.Now().AddDate(0, -1, 0).Format("2006-01-01")
	query :=
		`SELECT count(*) AS result FROM suite_execution
		WHERE timestamp BETWEEN '` + prev + `'::timestamptz AND '` + current + `'::timestamptz`

	ExecuteQueryHandler(w, query)
}

func AnalysisLastMonthTestsExecutedHandler(w http.ResponseWriter, r *http.Request) {
	current := time.Now().Format("2006-01-01")
	prev := time.Now().AddDate(0, -1, 0).Format("2006-01-01")
	query :=
		`SELECT count(*) AS result 
		FROM suite_execution_test set 
		JOIN suite_execution se ON set.id = se.id
		WHERE se.timestamp BETWEEN '` + prev + `'::timestamptz AND '` + current + `'::timestamptz`

	ExecuteQueryHandler(w, query)
}

func AnalysisLastMonthUniqueUserAgentsHandler(w http.ResponseWriter, r *http.Request) {
	current := time.Now().Format("2006-01-01")
	prev := time.Now().AddDate(0, -1, 0).Format("2006-01-01")
	query :=
		`SELECT COUNT(DISTINCT user_agent) AS result FROM suite_execution 
		WHERE timestamp BETWEEN '` + prev + `'::timestamptz AND '` + current + `'::timestamptz`

	ExecuteQueryHandler(w, query)
}
