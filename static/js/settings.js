// BrowserAudit client-side settings API

var browserAuditSettings = (function() {
	var queryString = URI(window.location).query(true);

	return {
		// categories: a comma-delimited list of categories to include in this test
		// suite execution (default=*, a synonym for "all categories")
		categories: (/^\d+(?:,\d+)*$/.test(queryString.categories) ? queryString.categories : "*"),

		// displaymode: full=include test reports; summary=include scoreboard;
		// none=no ui elements (default=full)
		displaymode: (/^(?:full|summary|none)$/.test(queryString.displaymode) ? queryString.displaymode : "full"),

		// sendresults: true=send test results back to BA server; false=don't
		// (default=true)
		sendresults: (/^(?:true|false)$/.test(queryString.sendresults) ? queryString.sendresults === "true" : true)
	};
})();
