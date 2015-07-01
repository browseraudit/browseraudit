// API for BrowserAudit user interface elements

var browserAuditUI = (function() {
	// The category tree table is only present on the home page
	var categoryTreeTable = $("#browseraudit-categories table");

	// The notification bar is in a fixed position at the top of the screen, and
	// can be interacted with by clicking on it
	var notificationBarContainerElement = $("div#notification-bar");
	var notificationBarElement = $("div#notification-bar .navbar").eq(0);
	var notificationBarTextElement = $("div#notification-bar .notification-bar-text").eq(0);

	// The scoreboard is at the top of the page, and provides a running tally of
	// the number of passed/failed/skipped tests along with a progress bar
	var scoreboardElements = {
		progressBar: {
			pass: $("div#browseraudit-bar-pass"),
			warning: $("div#browseraudit-bar-warning"),
			critical: $("div#browseraudit-bar-critical"),
			skip: $("div#browseraudit-bar-skip")
		},
		tally: {
			pass: $("h1#browseraudit-tally-pass"),
			warning: $("h1#browseraudit-tally-warning"),
			critical: $("h1#browseraudit-tally-critical"),
			skip: $("h1#browseraudit-tally-skip")
		}
	};
	var scoreboardTally = {
		pass: 0,
		warning: 0,
		critical: 0,
		skip: 0,
		total: 0
	};

	var categoryOutcomeStringFragments = {
		warning: "%COUNT% non-critical test%S% in this category failed.",
		critical: "%COUNT% critical test%S% in this category failed.",
		skip: "%COUNT% test%S% in this category %TENSE% skipped."
	};

	var testReportSummaryStringFragments = {
		executing: "This test is currently executing.",
		timeout: "Note that this result may be unreliable due to the test's use of a %TIMEOUT%ms timeout; your web browser may not have executed the test quickly enough, or your Internet connection may be too slow.",
		pass: "This test executed in &#x2248;%TIME%ms and <strong>passed</strong> for the following reason: <em>%REASON%</em>",
		warning: "This <strong>non-critical</strong> test executed in &#x2248;%TIME%ms and <strong>failed</strong> for the following reason: <em>%REASON%</em>",
		critical: "This <strong>critical</strong> test executed in &#x2248;%TIME%ms and <strong>failed</strong> for the following reason: <em>%REASON%</em>",
		skip: "This test was <strong>skipped</strong> for the following reason: <em>%REASON%</em>"
	};

	var beautify = {
		js: function(content) {
			return js_beautify(content, {
				"indent_size": 2,
				"indent_char": " ",
				"preserve_newlines": true,
				"max_preserve_newlines": 1
			});
		},
		html: function(content) {
			return html_beautify(content, {
				"indent_size": 2,
				"indent_char": " ",
				"selector_separator": '\n',
				"wrap_line_length": 0,
				"indent_inner_html": true,
				"indent_scripts": true,
				"preserve_newlines": true,
				"max_preserve_newlines": 1
			});
		},
		css: function(content) {
			return css_beautify(content, {
				"indent_size": 2,
				"indent_char": " ",
				"selector_separator_newline": true
			});
		}
	};

	var escapeHTMLEntities = function(html) {
		return html
			.replace(/&/g, '&amp;')
			.replace(/</g, '&lt;')
			.replace(/>/g, '&gt;')
			.replace(/"/g, '&quot;');
	};

	// jquerySelector should select <pre> elements -- all descendant <code> blocks
	// will be syntax-highlighted
	var syntaxHighlight = function(jqueryObject) {
		jqueryObject.find("code").each(function(i, block) {
			hljs.highlightBlock(block);
		});
	};

	var floorToPlaces = function(num, accuracy) {
		return +(Math.floor(num + "e+" + accuracy)  + "e-" + accuracy);
	};

	var publicInterface = {
		// The category selection panel is only present on the home page, and allows
		// the user to select the categories they want to include as part of the
		// test suite's execution
		categorySelectionPanel: {
			add: function(id, title, description, parent, inDefault) {
				var categoryElement =
					$("<tr>", { "class": "treegrid-"+id + (parent !== null ? " treegrid-parent-"+parent : "") })
					.append(
						$("<td>")
						.append(
							$("<div>", { "class": "category-checkbox" })
							.append(
								$("<input>", { "type": "checkbox", "id": "browseraudit-selected-"+id, "data-category": id })
								.prop("checked", inDefault)
								.change(function() {
									var isChecked = $(this).prop("checked");

									// Set checked status of all boxes that are children of this
									// one to the checked status of this box
									categoryTreeTable
										.find(".treegrid-"+id)
										.treegrid("getChildNodes")
										.find("input[type='checkbox']")
										.prop("indeterminate", false)
										.prop("checked", isChecked);

									// Propagate the checked status of this box to parent boxes
									// up to the root node, if other children at each level have
									// the same checked status; if they don't, use indeterminate
									// state instead
									var parentNode = categoryTreeTable.find(".treegrid-"+id).treegrid("getParentNode");
									while (parentNode !== null) {
										var childNodes = parentNode.treegrid("getChildNodes");
										var checkedChildNodes = childNodes.find("input[type='checkbox']:checked");
										if (checkedChildNodes.length === 0) {
											parentNode
												.find("input[type='checkbox'][data-category='"+parentNode.treegrid("getNodeId")+"']")
												.prop("indeterminate", false)
												.prop("checked", false);
										} else if (childNodes.length === checkedChildNodes.length) {
											parentNode
												.find("input[type='checkbox'][data-category='"+parentNode.treegrid("getNodeId")+"']")
												.prop("indeterminate", false)
												.prop("checked", true);
										} else {
											parentNode
												.find("input[type='checkbox'][data-category='"+parentNode.treegrid("getNodeId")+"']")
												.prop("checked", false)
												.prop("indeterminate", true);
										}
										parentNode = parentNode.treegrid("getParentNode");
									}
								})
							)
						)
						.append(
							$("<div>", { "class": "title" })
							.append(
								$("<label>", { "for": "browseraudit-selected-"+id })
								.html(title)
							)
							.append(
								$("<div>")
								.append(
									$("<small>")
									.html(description !== null ? description : "")
								)
							)
						)
					);

				// Find the correct position in which to insert this new category
				// element in the table DOM:
				// - If the category does not have a parent, append it to the end of the
				//   table
				if (parent === null) {
					categoryTreeTable.append(categoryElement);
				// - If the category has a parent and that parent currently has no
				//   children in the table, append it as a sibling of the parent element
				//   immediately following the parent element
				} else if (categoryTreeTable.find(".treegrid-parent-"+parent).length === 0) {
					categoryTreeTable.find(".treegrid-"+parent).after(categoryElement);
				// - If the category has a parent and that parent currently has children
				//   in the table, append it as a sibling of the parent element
				//   immediately following the last child element
				} else {
					categoryTreeTable.find(".treegrid-parent-"+parent).last().after(categoryElement);
				}
			},

			hierarchicalise: function() {
				categoryTreeTable.treegrid({
					"indentTemplate": "<div class=\"treegrid-indent\"></div>",
					"expanderTemplate": "<div class=\"treegrid-expander\"></div>",
					"initialState": "collapsed"
				});
			},

			getSelectedIDs: function() {
				return categoryTreeTable
					.find("input[type='checkbox']:checked")
					.map(function() { return $(this).attr("data-category"); })
					.get();
			}
		},

		settingsPanel: {
			scrollTo: function(settingName) {
				$("#browseraudit-settings").collapse("show");
				$("html").scrollTo("#browseraudit-settings .form-group[data-setting='"+settingName+"']");
			}
		},

		notificationBar: {
			hide: function() {
				notificationBarContainerElement.slideUp(300, function() {
					// Remove the current message and onclick handler
					notificationBarTextElement.empty();
					notificationBarElement.off("click");
					notificationBarElement.removeClass("navbar-clickable");
				});
			},

			setMessage: function(glyphicon, message, onclickFunction) {
				// Hide the notification bar container if it is currently visible
				notificationBarContainerElement.slideUp(300, function() {
					// Remove the current message and onclick handler
					notificationBarTextElement.empty();
					notificationBarElement.off("click");
					notificationBarElement.removeClass("navbar-clickable");
					
					// Add a glyphicon before the message, if desired
					if (glyphicon !== null) {
						notificationBarTextElement
							.append(
								$("<span>", { "class": "glyphicon glyphicon-"+glyphicon })
							);
					}

					// Add the new message
					notificationBarTextElement.append(message);

					// Attach new onclick handler
					if (onclickFunction !== null) {
						notificationBarElement.on("click", null, onclickFunction);
						notificationBarElement.addClass("navbar-clickable");
					}

					// Show the notification bar again
					notificationBarContainerElement.slideDown(300);
				});
			}
		},

		scoreboard: {
			hide: function() {
				$("#scoreboard").addClass("hide");
			},

			show: function() {
				$("#scoreboard-noscript").addClass("hide");
				$("#scoreboard").removeClass("hide");
			},

			setTotal: function(total) {
				scoreboardTally.total = total;
			},

			setOutcome: function(outcome, newValue) {
				//if (outcome.match(/^(?:pass|warning|critical|skip)$/)) throw "Test outcome must be one of 'pass', 'warning', 'critical' or 'skip'.";
				
				scoreboardTally[outcome] = newValue;
				scoreboardElements.tally[outcome].text(scoreboardTally[outcome]);

				// Set width of progress bars in scoreboard, rounded down to 2 decimal
				// places (rounding down means the total width of the stacked bars might
				// sometimes be 99.99%, but the missing 0.01% shouldn't be noticeable)
	      scoreboardElements.progressBar.pass.css("width", floorToPlaces(scoreboardTally.pass / scoreboardTally.total * 100, 2) + "%");
	      scoreboardElements.progressBar.warning.css("width", floorToPlaces(scoreboardTally.warning / scoreboardTally.total * 100, 2) + "%");
	      scoreboardElements.progressBar.critical.css("width", floorToPlaces(scoreboardTally.critical / scoreboardTally.total * 100, 2) + "%");
	      scoreboardElements.progressBar.skip.css("width", floorToPlaces(scoreboardTally.skip / scoreboardTally.total * 100, 2) + "%");
			},

			incrementOutcome: function(outcome) {
				//if (outcome.match(/^(?:pass|warning|critical|skip)$/)) throw "Test outcome must be one of 'pass', 'warning', 'critical' or 'skip'.";
			
				scoreboardElements.tally[outcome].text(++scoreboardTally[outcome]);

				// Set width of progress bars in scoreboard, rounded down to 2 decimal
				// places (rounding down means the total width of the stacked bars might
				// sometimes be 99.99%, but the missing 0.01% shouldn't be noticeable)
	      scoreboardElements.progressBar.pass.css("width", floorToPlaces(scoreboardTally.pass / scoreboardTally.total * 100, 2) + "%");
	      scoreboardElements.progressBar.warning.css("width", floorToPlaces(scoreboardTally.warning / scoreboardTally.total * 100, 2) + "%");
	      scoreboardElements.progressBar.critical.css("width", floorToPlaces(scoreboardTally.critical / scoreboardTally.total * 100, 2) + "%");
	      scoreboardElements.progressBar.skip.css("width", floorToPlaces(scoreboardTally.skip / scoreboardTally.total * 100, 2) + "%");
			}
		},

		// The execution information panel is shown below the scoreboard on results
		// pages
		executionInfoPanel: {
			hide: function() {
				$("#browseraudit-execution-info-panel").addClass("hide");
			},

			show: function() {
				$("#browseraudit-execution-info-panel").removeClass("hide");
			},

			addInfo: function(title, value, valueDetail, valueLabels, description) {
				// Create a new DOM element for the execution information panel,
				// containing the title and value (these must not be null when passed to
				// the function)
				var infoElement =
					$("<div>", { "class": "form-group" })
					.append(
						$("<label>", { "class": "col-sm-2 control-label" })
						.text(title)
					)
					.append(
						$("<div>", { "class": "col-sm-10" })
						.append(
							$("<p>", { "class": "value" })
							.append(
								$("<span>")
								.html(value)
							)
						)
					);

				// If a valueDetail was supplied, append it to the value element
				if (valueDetail !== null) {
					infoElement.find("p.value")
						.append(
							$("<span>", { "class": "small" })
							.html(valueDetail)
						);
				}

				// If any valueLabels were supplied, append them in order to the value
				// element, following the valueDetail (if there was one)
				if ($.isArray(valueLabels)) {
					$.each(valueLabels, function(i, label) {
						infoElement.find("p.value")
							.append(
								$("<span>", { "class": "label label-default" })
								.append(
									(label[0] === null ? null : $("<img>", { "src": label[0] }))
								)
								.append(
									$("<span>")
									.text(label[1])
								)
							);
					});
				}

				// If a description was supplied, add it as a sibling after the value
				// element
				if (description !== null) {
					infoElement.find("div.col-sm-10")
						.append(
							$("<p>", { "class": "description" })
							.html(description)
						);
				}
				
				// Finally, add the element to the execution information panel
				$("#browseraudit-execution-info-panel .form-horizontal").append(infoElement);
			},

			ready: function() {
				// Use timeago to automatically generate (and update) a fuzzy timestamp
				// based on the test suite execution timestamp
				$("time.ago").timeago();

				// Add valueLabels to the "browser identifier" info based on what we can
				// extract from the user agent string
				var uaLabels = $.grep([
					// Browser name and version:
					$.grep([ $.ua.browser.name, $.ua.browser.version ], function(e, i) { return e !== undefined; }).join(" "),
					// OS name and version:
					$.grep([ $.ua.os.name, $.ua.os.version ], function(e, i) { return e !== undefined; }).join(" ")
				], function(e, i) { return e.length > 0; });
				
				$.each(uaLabels, function(i, label) {
					$("tt.useragent").parent().parent()
					.append(
						$("<span>", { "class": "label label-default" })
						.append(
							$("<span>")
							.text(label)
						)
					);
				});
			}
		},

		// The list of test reports appears below the scoreboard on the test and
		// results pages
		testReportList: {
			show: function() {
				$("#browseraudit-test-results").removeClass("hide");
			},

			hide: function() {
				$("#browseraudit-test-results").addClass("hide");
			},

			addChild: function(child) {
				$("#browseraudit-category-root > .panel-body > .category-children").append(child.getDOMElement());
			},

			setCollapsed: function(isCollapsed) {
				if (isCollapsed) {
					$("#browseraudit-category-root").addClass("collapse");
				} else {
					$("#browseraudit-category-root").removeClass("collapse");
				}
			}
		},

		testReportCategory: function(id, title, description) {
			var domElement =
				$("<div>", { "class": "panel panel-default" })
				.append(
					$("<div>", { "class": "panel-heading" })
					.append(
						$("<h4>", { "class": "panel-title" })
						.append(
							$("<a>", { "href": "#browseraudit-category-"+id, "data-toggle": "collapse", "aria-expanded": "true", "aria-controls": "browseraudit-category-"+id })
							.text(title)
						)
						.append(
							$("<span>", { "class": "glyphicon glyphicon-hourglass browseraudit-active pull-right hide" })
							.attr("rel", "tooltip")
							.attr("title", "Tests in this category are currently executing.")
						)
						.append(
							$("<span>", { "class": "badge badge-info pull-right hide" })
						)
						.append(
							$("<span>", { "class": "badge badge-warning pull-right hide" })
						)
						.append(
							$("<span>", { "class": "badge badge-danger pull-right hide" })
						)
					)
				)
				.append(
					$("<div>", { "class": "panel-collapse collapse in", "id": "browseraudit-category-"+id })
					.append(
						$("<div>", { "class": "panel-body" })
						.append(
							$("<div>", { "class": "category-description" })
						)
						.append(
							$("<div>", { "class": "category-children" })
						)
					)
				);

			var bodyContainerElement = domElement.find("div#browseraudit-category-"+id).eq(0);

			var collapseLinkElement = domElement.find("h4.panel-title a").eq(0);

			var outcomeElements = {
				warning: domElement.find("span.badge-warning").eq(0),
				critical: domElement.find("span.badge-danger").eq(0),
				skip: domElement.find("span.badge-info").eq(0)
			};

			var childContainerElement = domElement.find("div.category-children").eq(0);

			var activeElement = domElement.find("span.browseraudit-active").eq(0);

			if (typeof description === "string" && description.length > 0) {
				domElement.find("div.category-description")
					.addClass("category-description-present")
					.html(description);
			}

			return {
				getDOMElement: function() {
					return domElement;
				},

				addChild: function(child) {
					// Category elements are panels and test elements are list items, so
					// the child container needs to be given the correct class to contain
					// one of these Bootstrap element types
					if (child.elementType === "category") {
						childContainerElement.addClass("panel-group");
					} else {
						childContainerElement.addClass("list-group");
					}

					childContainerElement.append(child.getDOMElement());
				},

				setActive: function(isActive) {
					if (isActive) {
						activeElement.removeClass("hide");
					} else {
						activeElement.addClass("hide");
					}
				},

				setOutcome: function(outcome, count) {
					outcomeElements[outcome]
						.removeClass("hide")
						.text(count)
						.attr("rel", "tooltip")
						.attr("title", categoryOutcomeStringFragments[outcome].replace("%COUNT%", count).replace("%S%", count === 1 ? "" : "s").replace("%TENSE%", count === 1 ? "was" : "were"));
				},

				setCollapsed: function(isCollapsed) {
					if (isCollapsed) {
						bodyContainerElement.removeClass("in");
						collapseLinkElement.attr("aria-expanded", "false");
					} else {
						bodyContainerElement.addClass("in");
						collapseLinkElement.attr("aria-expanded", "true");
					}
				}
			};
		},

		testReport: function(id, title, behaviour, timeout, testFunction, reportData) {
			var testResult = null;
			var testResultReason = null;
			var testExecutionTime = null;

			var domElement = 
				$("<div>", { "class": "list-group-item", "id": "browseraudit-test-"+id })
				.append(
					$("<table>")
					.append(
						$("<tr>")
						.append(
							$("<td>", { "class": "nowrap" })
							.append(
								$("<span>", { "class": "label label-default" })
								.text(behaviour === "allow" ? "Allow" : "Block")
								.attr("rel", "tooltip")
								.attr("title", behaviour === "allow" ? "This test relaxes a security policy and checks whether the web browser correctly allows a request that would usually violate the policy." : "This test strengthens a security policy and checks whether the web browser correctly blocks a request that violates the policy.")
							)
						)
						.append(
							$("<td>", { "class": "test-title" })
							.append(
								$("<a>", { "class": "list-group-item-heading", "href": "#browseraudit-test-"+id+"-report", "data-toggle": "collapse", "aria-expanded": "false", "aria-controls": "browseraudit-test-"+id+"-report" })
								.text(title)
							)
						)
						.append(
							$("<td>", { "class": "nowrap" })
							.append(
								$("<span>", { "class": "glyphicon glyphicon-time" })
							)
							.append(
								$("<span>", { "class": "glyphicon glyphicon-hourglass test-result" })
								.attr("rel", "tooltip")
								.attr("title", "This test is currently executing.")
							)
						)
					)
				)
				.append(
					$("<div>", { "class": "list-group-item-text well container-fluid collapse", "id": "browseraudit-test-"+id+"-report" })
					.on("show.bs.collapse", function() { showTestReportData(); })
					.on("hidden.bs.collapse", function() { reportDataContainer.empty(); })
				);

			var resultIconElement = domElement.find("span.test-result").eq(0);
			
			var reportDataContainer = domElement.find("div#browseraudit-test-"+id+"-report").eq(0);

			// dataType: one of "html", "css", "js", "http"
			var externalPreElement = function(reportDataComponent, dataType) {
				if (reportData.hasOwnProperty(reportDataComponent+"_content")) {
					var preElement =
						$("<pre>", { "class": "pre-scrollable" })
						.append(
							$("<code>", { "class": dataType })
							.html(beautify.hasOwnProperty(dataType) ? escapeHTMLEntities((beautify[dataType])(reportData[reportDataComponent+"_content"])) : escapeHTMLEntities(reportData[reportDataComponent+"_content"]))
						);
					return preElement;
				} else {
					var placeholderElement = $("<p>").html("Loading&hellip;");

					$.get(reportData[reportDataComponent])
						.done(function(data) {
							reportData[reportDataComponent+"_content"] = data;
							var preElement = externalPreElement(reportDataComponent, dataType);
							placeholderElement.replaceWith(preElement);
							syntaxHighlight(preElement);
						})
						.fail(function() {
							var failedElement = $("<p>").html("Loading failed; collapse and reopen this test report to try again.");
							placeholderElement.replaceWith(failedElement);
						});

					return placeholderElement;
				}
			};
			
			var reportDataComponents = {
				testFunction: {
					title: "Test function",
					tooltip: "This is the JavaScript function that BrowserAudit executed to perform this test.",
					preElement: function() {
						var preElement =
							$("<pre>", { "class": "pre-scrollable" })
							.append(
								$("<code>", { "class": "js" })
								.html(escapeHTMLEntities((beautify.js)(testFunction.toString())))
							);
						return preElement;
					}
				},
				iframeSrc: {
					title: "<code>&lt;iframe&gt;</code> source code",
					tooltip: "This test function dynamically creates an <code>&lt;iframe&gt;</code> as part of the test; this is its HTML source code.",
					preElement: function() { return externalPreElement("iframeSrc", "html"); }
				},
				iframeHTTPHeader: {
					title: "Additional HTTP header served with <code>&lt;iframe&gt;</code>",
					tooltip: "The <code>&lt;iframe&gt;</code> dynamically created by this test function was additionally served with the following HTTP header.",
					preElement: function() {
						var preElement =
							$("<pre>", { "class": "pre-scrollable" })
							.append(
								$("<code>", { "class": "http" })
								.text(reportData.iframeHTTPHeader)
							);
						return preElement;
					}
				},
				innerIframeSrc: {
					title: "Inner <code>&lt;iframe&gt;</code> source code",
					tooltip: "The <code>&lt;iframe&gt;</code> dynamically created by this test function dynamically creates its own nested <code>&lt;iframe&gt;</code>; this is its HTML source code.",
					preElement: function() { return externalPreElement("innerIframeSrc", "html"); }
				},
				stylesheetSrc: {
					title: "Stylesheet source code",
					tooltip: "The <code>&lt;iframe&gt;</code> dynamically created by this test function loads a dynamically-created external stylesheet; these are the CSS rules it contains.",
					preElement: function() { return externalPreElement("stylesheetSrc", "css"); }
				},
				innerStylesheetSrc: {
					title: "Inner stylesheet source code",
					tooltip: "The dynamically-created external stylesheet loaded by this test function loads another dynamically-created external stylesheet of its own; these are the CSS rules it contains.",
					preElement: function() { return externalPreElement("innerStylesheetSrc", "css"); }
				},
				ajaxHTTPHeader: {
					title: "Additional HTTP header served with AJAX response",
					tooltip: "The test function performed an AJAX request (e.g., via <code>$.ajax()</code> or <code>$.get()</code>), and the server's response to this request contained the following HTTP header.",
					preElement: function() {
						var preElement =
							$("<pre>", { "class": "pre-scrollable" })
							.append(
								$("<code>", { "class": "http" })
								.text(reportData.ajaxHTTPHeader)
							);
						return preElement;
					}
				},
				firstImageHTTPHeader: {
					title: "Additional HTTP header served with first image",
					tooltip: "The test function dynamically loaded images (i.e., by dynamically constructing <code>&lt;img&gt;</code> elements and inserting them into the page); the server's response to the <i>first</i> of these image-loading requests contained the following HTTP header.",
					preElement: function() {
						var preElement =
							$("<pre>", { "class": "pre-scrollable" })
							.append(
								$("<code>", { "class": "http" })
								.text(reportData.firstImageHTTPHeader)
							);
						return preElement;
					}
				}
			};

			var showTestReportData = function() {
				// Start with a skeleton for the test report data: a container with one
				// row and one column that will hold the outcome of the test
				reportDataContainer
				.append(
					$("<div>", { "class": "container-fluid" })
					.append(
						$("<div>", { "class": "row" })
						.append(
							$("<div>", { "class": "browseraudit-report-outcome-container col-md-12" })
							.append(
								$("<div>", { "class": "alert alert-default" })
								.html(testReportSummaryStringFragments.executing)
							)
						)
					)
				);

				// Insert the outcome of the test, if this test has already finished
				// executing
				if (testResult !== null) updateTestReportData();

				// For each possible piece of test report data, add a new row if this
				// piece of data exists for this test
				$.each([ "testFunction", "ajaxHTTPHeader", "firstImageHTTPHeader", "iframeSrc", "iframeHTTPHeader", "innerIframeSrc", "stylesheetSrc", "innerStylesheetSrc" ], function(k, reportDataComponent) {
					if (reportDataComponent === "testFunction" || reportData.hasOwnProperty(reportDataComponent)) {
						reportDataContainer.find("div.container-fluid").eq(0)
						.append(
							$("<div>", { "class": "row" })
							.append(
								$("<div>", { "class": "col-md-3" })
								.append(
									$("<p>")
									.html(reportDataComponents[reportDataComponent].title + ":")
								)
							)
							.append(
								$("<div>", { "class": "col-md-9" })
								.append(
									reportDataComponents[reportDataComponent].preElement()
								)
							)
						);
					}
				});
				syntaxHighlight(reportDataContainer.find("pre"));
			};

			var updateTestReportData = function() {
				reportDataContainer.find("div.alert-default").html(
					testReportSummaryStringFragments[testResult].replace("%TIME%", testExecutionTime).replace("%REASON%", testResultReason) +
					(testResult === "skip" || timeout === null ? "" : " "+testReportSummaryStringFragments.timeout.replace("%TIMEOUT%", timeout))
				);
			};

			// If execution of the test function involves the use of the timeout, show
			// the timeout icon and apply a tooltip; otherwise, hide the tooltip icon
			if (timeout === null) {
				domElement.find(".glyphicon-time")
					.addClass("hide");
			} else {
				domElement.find(".glyphicon-time")
					.attr("rel", "tooltip")
					.attr("title", "This test relies upon a "+timeout+"ms timeout.");
			}

			return {
				getDOMElement: function() {
					return domElement;
				},

				setResult: function(result, reason, executionTime) {
					if (result === "pass") {
						resultIconElement
							.removeClass("glyphicon-hourglass glyphicon-alert glyphicon-remove glyphicon-asterisk hide")
							.addClass("glyphicon-ok")
							.attr("title", "The web browser passed this test.");

						domElement
							.removeClass("list-group-item-warning list-group-item-danger list-group-item-info");
					} else if (result === "warning") {
						resultIconElement
							.removeClass("glyphicon-hourglass glyphicon-ok glyphicon-remove glyphicon-asterisk hide")
							.addClass("glyphicon-alert")
							.attr("title", "The web browser failed this non-critical test.");
						
						domElement
							.removeClass("list-group-item-danger list-group-item-info")
							.addClass("list-group-item-warning");
					} else if (result === "critical") {
						resultIconElement
							.removeClass("glyphicon-hourglass glyphicon-ok glyphicon-alert glyphicon-asterisk hide")
							.addClass("glyphicon-remove")
							.attr("title", "The web browser failed this critical test.");

						domElement
							.removeClass("list-group-item-warning list-group-item-info")
							.addClass("list-group-item-danger");
					} else { // result === "skip"
						resultIconElement
							.removeClass("glyphicon-hourglass glyphicon-ok glyphicon-alert glyphicon-remove hide")
							.addClass("glyphicon-asterisk")
							.attr("title", "This test was skipped.");

						domElement
							.removeClass("list-group-item-danger list-group-item-danger")
							.addClass("list-group-item-info");
					}

					// If the test report outcome is expanded, write the test result into
					// the top alert box
					testResult = result;
					testResultReason = reason;
					testExecutionTime = executionTime;
					updateTestReportData();
				}
			};
		}
	};

	return publicInterface;
})();
