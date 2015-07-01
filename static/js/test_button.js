$(".browseraudit-start").on("click", function() {
	var testURI = new URI(window.location).pathname("/test");

	// Categories to include in test suite execution
	testURI.addSearch("categories", browserAuditUI.categorySelectionPanel.getSelectedIDs().join(","));

	// Display mode
	if ($("input[name=displaymode]:checked").val() !== "full") {
		testURI.addSearch("displaymode", $("input[name=displaymode]:checked").val());
	}

	// Test result reporting
	if ($("input[name=sendresults]:checked").val() !== "true") {
		testURI.addSearch("sendresults", $("input[name=sendresults]:checked").val());
	}
	
	// Redirect to /test with chosen settings in the query string --- they will be
	// parsed by settings.js on the test page
	window.location = testURI;
});
