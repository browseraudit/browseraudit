var browserAuditTestFramework = (function() {
	// A hierarchy of categories and tests that form the test suite; this is
	// dynamically created via calls to the addCategory() and addTest() functions
	var hierarchy = {
		nodeType: "root",
		title: "BrowserAudit test suite", // Not actually used
		description: "The organised list of tests to be executed", // Not actually used
		children: [],
		childrenType: ""
	};

	// A 2-dimensional array mapping category IDs (that were previously inserted
	// into the category hierarchy via calls to the addCategory() function) to the
	// category's position in the hierarchy; each element in the array for a given
	// category ID represents an array offset in the "children" property, starting
	// with hierarchy.children
	var categoryTrail = {};

	// TODO: Document this
	var testTrail = {};

	var testTotal = 0;

	// Is test execution currently running? (While this is set to true, calls to
	// start() will be forbidden)
	var testSuiteExecuting = false;

	// Is test suite execution currently paused? (While this is set to true, tests
	// that have not begun executing will not be executed)
	var testSuiteExecutionPaused = false;

	var options = {};
	var nodeStack = [ hierarchy.children ];
	var nodeStackPointers = [ 0 ];
	var resultStack = [ { pass: 0, warning: 0, critical: 0, skip: 0 } ];
	var resultTypes = [ "pass", "warning", "critical", "skip" ];

	// Returns the node for a given a category ID in the category hierarchy
	var getCategoryNode = function(categoryID) {
		if (!categoryTrail.hasOwnProperty(categoryID)) throw "A category with this ID has not been added to the hierarchy.";

		var trail = categoryTrail[categoryID].concat();
		var theCategory = hierarchy;
		while (trail.length > 0) theCategory = theCategory.children[trail.shift()];

		return theCategory;
	};

	// TODO: Document this
	var visitHierarchyNode = function() {
		// If test suite execution is paused, don't visit any nodes for now
		if (testSuiteExecutionPaused) return;

		// Find the node we need to visit in this call to the function
		var thisNode = nodeStack[nodeStack.length - 1][nodeStackPointers[nodeStackPointers.length - 1]];

		// XXX: console.debug("Visiting node: type=%s, title=%s", thisNode.nodeType, thisNode.title);

		// If we're visiting a category, run the startCategory() callback
		// function
		if (thisNode.nodeType === "category") {
			if (options.hasOwnProperty("startCategory")) options.startCategory.call(thisNode);

			markHierarchyNode(thisNode.nodeType, thisNode.id, null, null);
		// If we're visiting a test, run the startTest() callback function, then
		// execute the test function
		} else {
			if (options.hasOwnProperty("startTest")) options.startTest.call(thisNode);

			// Track the time this test function began executing, so we can report
			// (approximately) how long it took to execute afterwards
			var testStartTime = +new Date();

			// Give the test function 10 seconds to execute before skipping it
			var testTimer = setInterval(function() {
				markHierarchyNode(thisNode.nodeType, thisNode.id, testStartTime, [ "skip", "The test timed out (it did not finish executing within 10 seconds)." ], testTimer);
			}, 10000);

			// Execute the test function, using a "test harness" object as the
			// context (i.e. the "this" object)
			thisNode.testFunction.call({
				PASS: function(reason) { markHierarchyNode(thisNode.nodeType, thisNode.id, testStartTime, [ "pass", reason ], testTimer); },
				WARNING: function(reason) { markHierarchyNode(thisNode.nodeType, thisNode.id, testStartTime, [ "warning", reason ], testTimer); },
				CRITICAL: function(reason) { markHierarchyNode(thisNode.nodeType, thisNode.id, testStartTime, [ "critical", reason ], testTimer); },
				SKIP: function(reason) { markHierarchyNode(thisNode.nodeType, thisNode.id, testStartTime, [ "skip", reason ], testTimer); }
			});
		}
	};

	// TODO: document this
	var markHierarchyNode = function(nodeType, nodeID, testStartTime, result, testTimer) {
		// Record the time this function was called: the current time minus the
		// reported start time will be roughly the execution time of the test
		// function
		var testExecutionTime = (new Date()) - testStartTime;

		// If testTimer isn't null, it'll be the ID of the timer that is due to
		// time-out the execution of this test's test function: stop that timer
		if (typeof testTimer !== null) clearInterval(testTimer);

		// Find the node we need to mark as visited in this call to the function
		var thisNode = nodeStack[nodeStack.length - 1][nodeStackPointers[nodeStackPointers.length - 1]];

		// If this is a test function reporting its result after the timeout,
		// the node type/ID triggering this function call won't match the node
		// type/ID on top of the node stack. In this case, ignore the result:
		// we've already moved on
		if (nodeType !== thisNode.nodeType || nodeID !== thisNode.id) return;
		
		// XXX: console.debug("Marking node: type=%s, title=%s", thisNode.nodeType, thisNode.title);

		if (thisNode.nodeType === "test") {
			// Update the last element in the result stack with the result that is
			// being reported
			resultStack[resultStack.length - 1][result[0]]++;
			
			// Run the endTest() callback function
			if (options.hasOwnProperty("endTest")) options.endTest.call(thisNode, testExecutionTime, result);
		}

		// Prepare the node stack and pointer array for the next time this
		// function is called: they need to point to the next node to be visited
		var topOfResultStack;
		var nextNodeFound = false;
		while (!nextNodeFound) {
			// If this node has children of its own, they should be visited next
			if (thisNode.nodeType === "category") {
				if (thisNode.children.length === 0) {
					if (options.hasOwnProperty("endCategory")) options.endCategory.call(thisNode, { pass: 0, warning: 0, critical: 0, skip: 0 });
					// On the next iteration of the while loop, this makes sure we
					// don't end up back in the first branch of the if statement again
					// (ugly, but it does the job)
					thisNode.nodeType = "emptyCategory";
				} else {
					nodeStack.push(thisNode.children);
					nodeStackPointers.push(0);
					resultStack.push({ pass: 0, warning: 0, critical: 0, skip: 0 });
					nextNodeFound = true;
				}
			// Otherwise, keep visiting this node's siblings: increment the final
			// element in the pointer array and check whether a node exists in
			// that position in the corresponding array in the node stack; if a
			// node exists there, visit that one next
			} else if (++nodeStackPointers[nodeStackPointers.length - 1] < nodeStack[nodeStack.length - 1].length) {
				nextNodeFound = true;
			// Otherwise, we've finished visiting all of the nodes in the deepest
			// level of the node stack
			} else {
				// Remove this array from the node stack
				nodeStack.pop();
				nodeStackPointers.pop();
				var topOfResultStack = resultStack.pop();

				if (nodeStack.length !== 0) {
					// The top element on the node stack now points to the node whose
					// children have all been visited: if this node is a category,
					// call the endCategory() callback function
					var finishedVisitingNode = nodeStack[nodeStack.length - 1][nodeStackPointers[nodeStackPointers.length - 1]];
					
					if (finishedVisitingNode.nodeType === "category") {
						// Fold the result tallies for this level into the element now
						// on top of the result stack
						if (resultStack.length !== 0) {
							for (var i = 0; i < resultTypes.length; i++) {
								resultStack[resultStack.length - 1][resultTypes[i]] += topOfResultStack[resultTypes[i]];
							}
						}

						if (options.hasOwnProperty("endCategory")) options.endCategory.call(finishedVisitingNode, topOfResultStack);
					}
				} else {
					// If the node stack is empty, we've visited all of the nodes in
					// the hierarchy. We know what the "next" node is: there isn't one
					nextNodeFound = true;
				}
			}
		}

		// If the node stack is non-empty, visit the next node; if it is empty,
		// call the endSuite() callback function
		setTimeout(function() {
			if (nodeStack.length !== 0) {
				visitHierarchyNode();
			} else {
				testSuiteExecuting = false;
				testSuiteExecutionPaused = false;
				if (options.hasOwnProperty("endSuite")) options.endSuite.call(null, topOfResultStack);
			}
		}, 25);
	};

  var publicFramework = {
		// Adds a test category to the test suite; tests will be executed in the
		// order in which their category was added to the test suite (per a depth-
		// first search of the category hierarchy), then in the order in which the
		// tests themselves were added to the category using the addTest() function
		// Parameters:
		// - categoryID: a unique identifier for this category
		// - parentCategoryID: the ID of the parent category, or null if this is a
		//   top-level category
		// - title: a title for the category, to be displayed to the user in the
		//   results section (may contain HTML)
		// - description: a description for the category, to be displayed to the
		//   user in the results section (may contain HTML)
		addCategory: function(categoryID, parentCategoryID, title, description) {
      // The category ID can't be used twice
      if (categoryTrail.hasOwnProperty(categoryID)) throw "A category with this ID has already been added to the test suite.";

      // The parent category ID must be null, or must have been added to the
			// test suite already
			if (parentCategoryID !== null && !categoryTrail.hasOwnProperty(parentCategoryID)) throw "The parent category's ID must have been added as a category already, or the parent category ID must be null (indicating that this is a top-level test category).";

			// TODO: Either categories or tests may be added as children of the parent
			// category, but not both

      // If the parent category ID is null, we can just insert this new category
			// at the end of the top level of the hierarchy
			if (parentCategoryID === null) {
				hierarchy.children.push({
					nodeType: "category",
					id: categoryID,
          title: title,
					description: description,
					children: [],
					childrenType: ""
				});

				categoryTrail[categoryID] = [ hierarchy.children.length - 1 ];

			// Otherwise, we need to find the new category's parent category in the
			// hierarchy and insert the new category as a child of the parent
			} else {
				var parentCategory = getCategoryNode(parentCategoryID);

				parentCategory.children.push({
					nodeType: "category",
					id: categoryID,
          title: title,
					description: description,
					children: [],
					childrenType: ""
				});

				categoryTrail[categoryID] = categoryTrail[parentCategoryID].concat(parentCategory.children.length - 1);
			}

      // XXX: console.debug("Added category " + categoryID + ": " + title);
			// XXX: console.debug("New hierarchy: %o", hierarchy);
			// XXX: console.debug("New category trail: %o", categoryTrail);
		},

		// Adds a test to the test suite under a particular category; tests
		// belonging to the same category are executed in the order in which they
		// were added to the category
		// Parameters:
		// - testID: a unique identifier for this test
		// - categoryID: the ID of the category to which this test belongs (a test
		//   *must* belong to a category)
		// - title: a title for the test, to be displayed to the user in the results
		//   section (may contain HTML)
		// - timeout: if the test function uses timeouts, an integer representing
		//   the amount of time (in ms) that the timeout lasts; null if the test
		//   function does not use timeouts
		// - testFunction: the function that will be executed; the function should
		//   return one of the following values, where "reason" is a string
		//   describing the reason the test ended in that state:
		//   * result.PASS(reason) if the test passes;
		//   * result.WARNING(reason) if the test fails, but failing this test is
		//     non-critical;
		//   * result.CRITICAL(reason) if the test fails, and failing this test is
		//     critical;
		//   * result.SKIP(reason) if the test was skipped
    //   the function may also have a property "reportData", which is an object
		//   containing the following properties:
		//   TODO: Document reportData
		addTest: function(testID, categoryID, title, behaviour, timeout, testFunction) {
			// The test ID can't be used twice
      if (testTrail.hasOwnProperty(testID)) throw "A test with this ID has already been added to the test suite.";

			// A category with the given ID must have been added to the test suite
			// already, via the addCategory() function
			if (!categoryTrail.hasOwnProperty(categoryID)) throw "A category with the given ID must have been added to the test suite already.";

			// Note this test ID so we can forbid future attempts to add a test with
			// the same ID
			testTrail[testID] = 1;

			// Add the test as a child of the node representing the given category ID
			getCategoryNode(categoryID).children.push({
				nodeType: "test",
				id: testID,
				title: title,
				behaviour: behaviour,
				timeout: timeout,
				testFunction: testFunction
			});

			testTotal++;

      // XXX: console.debug("Added test " + testID + ": " + title);
			// XXX: console.debug("New hierarchy: %o", hierarchy);
		},

		getTestTotal: function() {
			return testTotal;
		},

    start: function(callbacks) {
			// Don't run the test suite if it has already been run
			if (testSuiteExecuting) throw "The BrowserAudit test suite is currently executing.";
			testSuiteExecuting = true;
			testSuiteExecutionPaused = false;

			options = callbacks;

			// Call the startSuite() callback function, then run the test suite
			if (options.hasOwnProperty("startSuite")) {
				options.startSuite.call(null, visitHierarchyNode);
			} else {
				visitHierarchyNode();
			}
		},

		pause: function() {
			if (!testSuiteExecuting) throw "The BrowserAudit test suite is not currently executing.";

			testSuiteExecutionPaused = true;
			if (options.hasOwnProperty("pauseSuite")) options.pauseSuite.call(null);
		},

		resume: function() {
			if (!testSuiteExecuting) throw "The BrowserAudit test suite is not currently executing.";

			testSuiteExecutionPaused = false;
			if (options.hasOwnProperty("resumeSuite")) options.resumeSuite.call(null);
			visitHierarchyNode();
		}
	};

	return publicFramework;
})();
