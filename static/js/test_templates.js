// These functions build and return the actual test functions that are executed
// by the BrowserAudit test framework (the eventual aim is for all test
// functions to be stored in and automatically extracted from the database
// on-demand, making this file unnecessary)

// Same-Origin Policy -> DOM access
// Same-Origin Policy -> DOM access - parent https://browseraudit.com, child https://test.browseraudit.com - child accessing parent
// Same-Origin Policy -> DOM access - parent https://browseraudit.com, child https://test.browseraudit.com - parent accessing child
// Same-Origin Policy -> DOM access - parent https://test.browseraudit.com, child https://browseraudit.com - child accessing parent
// Same-Origin Policy -> DOM access - parent https://test.browseraudit.com, child https://browseraudit.com - parent accessing child
var parentChildSopTest = function(testID, shouldBeBlocked, fromParent, parentPrefix, parentDocumentDomain, childPrefix, childDocumentDomain) {
  var defaultResult = (shouldBeBlocked) ? "pass" : "fail";
  var nresult = (defaultResult === "pass") ? "fail" : "pass";
  var p2c = fromParent ? "p2c" : "c2p";
  var childSrc = childPrefix+"/sop/"+p2c+"/child/"+(fromParent?"":(testID+"/"))+childDocumentDomain+(fromParent?"":("/"+nresult));
  var parSrc = parentPrefix+"/sop/"+p2c+"/parent/"+(fromParent?(testID+"/"):"")+parentDocumentDomain+(fromParent?("/"+nresult):"")+"/"+$.base64.encode(childSrc);

	var passBehaviourText = (shouldBeBlocked) ? "unable" : "able";
	var failBehaviourText = (shouldBeBlocked) ? "able" : "unable";
	var fromText = (fromParent) ? "parent iframe" : "child iframe";
	var toText = (fromParent) ? "child iframe" : "parent iframe";

	var reportData = {
		iframeSrc: parSrc.replace(/(test\.)?browseraudit\.(com|org)/, "browseraudit.com").concat("?serveOnly=true")
	};

	// When fromParent = true, there's no inner iframe
	if (!fromParent) {
		reportData.innerIframeSrc = childSrc.replace(/(test\.)?browseraudit\.(com|org)/, "browseraudit.com").concat("?serveOnly=true");
	}

  var test_template = function() {
		var thisTest = this;
    $.get("/sop/"+defaultResult+"/"+testID, function() {
      $("<iframe>", { src: parSrc }).appendTo("div#sandbox").load(function() {
        $.get("/sop/result/"+testID, function(result) {
					if (result === "pass") {
						thisTest.PASS("The "+fromText+" was "+passBehaviourText+" to access the "+toText+"'s DOM.");
					} else {
						thisTest.CRITICAL("The "+fromText+" was "+failBehaviourText+" to access the "+toText+"'s DOM.");
					}
        });
      });
    });
  };

  var test_source = test_template.toString()
		.replace('"+defaultResult+"', defaultResult)
		.replace(/"\+testID/g, testID+'"')
		.replace('parSrc', '"'+parSrc+'"')
		.replace(/"\+fromText\+"/g, fromText)
		.replace('"+passBehaviourText+"', passBehaviourText)
		.replace(/"\+toText\+"/g, toText)
		.replace('"+failBehaviourText+"', failBehaviourText);
  test_template.toString = function() { return test_source; };
	test_template.reportData = reportData;

  return test_template;
};

// Same-Origin Policy -> XMLHttpRequest
var ajaxSopTest = function(testID, shouldBeBlocked, sourcePrefix, destPrefix) {
  var defaultResult = (shouldBeBlocked) ? "pass" : "fail";
  var result = (defaultResult === "pass") ? "fail" : "pass";
  var dest = destPrefix+"/sop/"+result+"/"+testID;
  var destBase64 = $.base64.encode(dest);
  var iframeSrc = sourcePrefix+"/sop/ajax/"+testID+"/"+result+"/"+destBase64;

	var passBehaviourText = (shouldBeBlocked) ? "was not" : "was";
	var failBehaviourText = (shouldBeBlocked) ? "was" : "was not";
	
	var reportData = {
		iframeSrc: iframeSrc.replace(/(test\.)?browseraudit\.(com|org)/, "browseraudit.com").concat("?serveOnly=true")
	};

  var test_template = function() {
		var thisTest = this;
    $.get("/sop/"+defaultResult+"/"+testID, function() {
      $("<iframe>", { src: iframeSrc }).appendTo("div#sandbox").load(function() {
        $.get("/sop/result/"+testID, function(result) {
					if (result === "pass") {
						thisTest.PASS("The XMLHttpRequest request "+passBehaviourText+" received by the server.");
					} else {
						thisTest.CRITICAL("The XMLHttpRequest request "+failBehaviourText+" received by the server.");
					}
        });
      });
    });
  };

  var test_source = test_template.toString()
		.replace('"+defaultResult+"', defaultResult)
		.replace(/"\+testID/g, testID+'"')
		.replace('iframeSrc', '"'+iframeSrc+'"')
		.replace('"+passBehaviourText+"', passBehaviourText)
		.replace('"+failBehaviourText+"', failBehaviourText);
  test_template.toString = function() { return test_source; };
	test_template.reportData = reportData;

  return test_template;
};

// Same-Origin Policy -> Cookies - domain scope
// Same-Origin Policy -> Cookies - illegal domain scope
var domainScopeCookieTest = function(testID, shouldBeUnset, domainSetFrom, cookieDomain, domainAccessedFrom) {
  domainScopeCookieTest.id = domainScopeCookieTest.id || 0;

  var id = domainScopeCookieTest.id++;
  var timestamp = "" + new Date().getTime();
  var name = "sopscope"+id+timestamp;
  var value = (shouldBeUnset?"none":timestamp);
  var domain = cookieDomain;
  var path = "/";
  var img1path = "https://"+domainSetFrom+"/sop/cookie/"+name+"/"+timestamp+"/"+domain+"/"+$.base64.encode(path);
  var img2path = "https://"+domainAccessedFrom+"/sop/save_cookie/"+name;
	
	var passBehaviourText = (shouldBeUnset) ? "was not" : "was";
	var failBehaviourText = (shouldBeUnset) ? "was" : "was not";

  var test_template = function() {
		var thisTest = this;
    $("<img>", { src: img1path }).load(function() {
      $("<img>", { src: img2path }).load(function() {
        $.get("/sop/get_cookie/"+name, function(c) {
          $.removeCookie(name);

          if (c == value) {
						thisTest.PASS("The cookie "+passBehaviourText+" sent with the request.");
					} else {
						thisTest.CRITICAL("The cookie "+failBehaviourText+" sent with the request.");
					}
        });
      });
    });
  };

  var test_source = test_template.toString()
		.replace('img1path', '"'+img1path+'"')
		.replace('img2path', '"'+img2path+'"')
		.replace('"+name', name+'"')
		.replace('value', '"'+value+'"')
		.replace('name', '"'+name+'"')
		.replace('"+passBehaviourText+"', passBehaviourText)
		.replace('"+failBehaviourText+"', failBehaviourText);
  test_template.toString = function() { return test_source; };
	test_template.reportData = {};

  return test_template;
};

// Same-Origin Policy -> Cookies - path scope
var cookiePathScope = function(testID, shouldBeBlocked, name) {
  var value = "" + new Date().getTime();
  var domain = ".browseraudit.com";
  var path = "/sop/path/";
  var imgSrc1 = "/sop/path/cookie/"+name+"/"+value+"/"+domain+"/"+$.base64.encode(path);
  var simgSrc1 = "\"/sop/path/cookie/"+name+"/"+value+"/"+domain+"/\"+$.base64.encode(\""+path+"\")";
  var imgSrc2 = "/sop"+(shouldBeBlocked?"":"/path")+"/save_cookie/"+name;
  value = (shouldBeBlocked) ? "none" : value;

	var passBehaviourText = (shouldBeBlocked) ? "was not" : "was";
	var failBehaviourText = (shouldBeBlocked) ? "was" : "was not";

  var test_template = function() {
		var thisTest = this;
    $("<img>", { src: imgSrc1 }).load(function() {
      $("<img>", { src: imgSrc2 }).load(function() {
        $.get("/sop/get_cookie/"+name, function(c) {
          $.removeCookie(name);
          
					if (c == value) {
						thisTest.PASS("The cookie "+passBehaviourText+" sent with the request.");
					} else {
						thisTest.CRITICAL("The cookie "+failBehaviourText+" sent with the request.");
					}
        });
      });
    });
  };

  var test_source = test_template.toString()
		.replace('imgSrc1', simgSrc1)
		.replace('imgSrc2', '"'+imgSrc2+'"')
		.replace('"+name', name+'"')
		.replace('value', '"'+value+'"')
		.replace('"+passBehaviourText+"', passBehaviourText)
		.replace('"+failBehaviourText+"', failBehaviourText);
  test_template.toString = function() { return test_source; };
	test_template.reportData = {};

  return test_template;
};

// Content Security Policy
var cspTest = function(testID, cspID, policy, shouldBeBlocked, opts) {
  var policyBase64 = $.base64.encode(policy);
  var defaultResult = (shouldBeBlocked) ? "pass" : "fail";
  var iframe_src = "/csp/serve/" + cspID + "/param-html?policy=" + policyBase64 + "&defaultResult=" + defaultResult;

	var passBehaviourText = (shouldBeBlocked) ? "was not" : "was";
	var failBehaviourText = (shouldBeBlocked) ? "was" : "was not";

	var reportData = {
    iframeSrc: iframe_src,
		iframeHTTPHeader: "Content-Security-Policy: " + policy
	};

	// Some CSP tests have other resources which should also be shown in the test
	// result detail box:
	// - CSP test IDs 34, 36, 132-143, 150-167 are font-src tests with external
	//   stylesheets
	if ((cspID === 34) || (cspID === 36) || (132 <= cspID && cspID <= 143) || (150 <= cspID && cspID <= 167)) {
		reportData.stylesheetSrc = "/csp/serve/" + cspID + "/param-css";
	}
	// - CSP test IDs 140-143, 162-167 are font-src tests with external stylesheets
	//   loading their own inner stylesheets
	if ((140 <= cspID && cspID <= 143) || (162 <= cspID && cspID <= 167)) {
		reportData.innerStylesheetSrc = "/csp/serve/" + cspID + "/param-cssb";
	}
	// - CSP test IDs 200-211, 220-229 are sandbox tests with inner iframes
	if ((200 <= cspID && cspID <= 211) || (220 <= cspID && cspID <= 229)) {
		reportData.innerIframeSrc = "/csp/serve/" + cspID + "/param-htmlb?policy=" + policyBase64 + "&defaultResult=" + defaultResult;

		// CSP test IDs 208-211 additionally require a cookieDomain parameter
		if (208 <= cspID && cspID <= 211) {
			reportData.innerIframeSrc += "&cookieDomain=browseraudit.com";
		}
  }

	// Many CSP tests have prerequisites, otherwise they should be skipped; the
	// following resolves the dependencies necessary for each sub-category of CSP
	// test and ensures that the correct check appears in the test function body,
	// so the user can see what (if any) prerequisite is necessary for a CSP test
	// to execute
	// - Test IDs 217-220 require the Worker API
	if (217 <= testID && testID <= 220) {
		var prerequisiteMet = [ Modernizr.webworkers ];
		var prerequisiteText = [ "!Modernizr.webworkers" ];
		var prerequisiteSkipMessages = [ "The Worker API is not supported by this web browser." ];
	// - Test IDs 221-224 require the SharedWorker API
	} else if (221 <= testID && testID <= 224) {
		var prerequisiteMet = [ Modernizr.sharedworkers ];
		var prerequisiteText = [ "!Modernizr.sharedworkers" ];
		var prerequisiteSkipMessages = [ "The SharedWorker API is not supported by this web browser." ];
	// - Test IDs 241-260 require Flash Player to be installed and for the browser
	//   not to be blocking it on browseraudit.com
	} else if (241 <= testID && testID <= 260) {
		var prerequisiteMet = [ Modernizr.flash, !Modernizr.flash.blocked ];
		var prerequisiteText = [ "!Modernizr.flash", "Modernizr.flash.blocked" ];
		var prerequisiteSkipMessages = [ "The Flash Player plugin is not installed in this web browser.", "The web browser is blocking the Flash Player plugin on this web page." ];
	// - Test IDs 271-280 require HTML5 audio support
  } else if (271 <= testID && testID <= 280) {
		var prerequisiteMet = [ Modernizr.audio ];
		var prerequisiteText = [ "!Modernizr.audio" ];
		var prerequisiteSkipMessages = [ "HTML5 audio is not supported by this web browser." ];
	// - Test IDs 281-290 require HTML5 video support
  } else if (281 <= testID && testID <= 290) {
		var prerequisiteMet = [ Modernizr.video ];
		var prerequisiteText = [ "!Modernizr.video" ];
		var prerequisiteSkipMessages = [ "HTML5 video is not supported by this web browser." ];
	// - Test IDs 311-350 require CSS3 @font-face support
  } else if (311 <= testID && testID <= 350) {
		var prerequisiteMet = [ Modernizr.fontface ];
		var prerequisiteText = [ "!Modernizr.fontface" ];
		var prerequisiteSkipMessages = [ "The CSS3 @font-face rule is not supported by this web browser." ];
	// - Test IDs 361-372 require the WebSocket API
	} else if (361 <= testID && testID <= 372) {
		var prerequisiteMet = [ Modernizr.websockets ];
		var prerequisiteText = [ "!Modernizr.websockets" ];
		var prerequisiteSkipMessages = [ "The WebSocket API is not supported by this web browser." ];
	// - Test IDs 373-382 require the EventSource API
	} else if (373 <= testID && testID <= 382) {
		var prerequisiteMet = [ Modernizr.eventsource ];
		var prerequisiteText = [ "!Modernizr.eventsource" ];
		var prerequisiteSkipMessages = [ "The EventSource API is not supported by this web browser." ];
	// - Test IDs 383-402 require support for the "sandbox" attribute on <iframe>
	//   elements
	} else if (383 <= testID && testID <= 402) {
		var prerequisiteMet = [ Modernizr.sandbox ];
		var prerequisiteText = [ "Modernizr.sandbox" ];
		var prerequisiteSkipMessages = [ "The <iframe> 'sandbox' attribute is not supported by this web browser." ];
	}

	var test_template = (typeof opts.timeout === "undefined") ?
		function() {
			var thisTest = this;
			// == BEGIN PREREQUISITE CHECKS ==
			if (typeof prerequisiteMet !== "undefined") {
				for (var p = 0; p < prerequisiteMet.length; p++) {
					if (!prerequisiteMet[p]) thisTest.SKIP(prerequisiteSkipMessages[p]);
				}
			}
			// == END PREREQUISITE CHECKS ==
			$("<iframe>", { src: iframe_src }).appendTo("div#sandbox").load(function() {
				$.get("/csp/result/"+cspID, function(result) {
					if (result === "pass") {
						thisTest.PASS("The resource request "+passBehaviourText+" received by the server.");
					} else {
						thisTest.WARNING("The resource request "+failBehaviourText+" received by the server.");
					}
				});
			});
		} : function() {
			var thisTest = this;
			// == BEGIN PREREQUISITE CHECKS ==
			if (typeof prerequisiteMet !== "undefined") {
				for (var p = 0; p < prerequisiteMet.length; p++) {
					if (!prerequisiteMet[p]) thisTest.SKIP(prerequisiteSkipMessages[p]);
				}
			}
			// == END PREREQUISITE CHECKS ==
			$("<iframe>", { src: iframe_src }).appendTo("div#sandbox").load(function() {
				setTimeout(function() {
					$.get("/csp/result/"+cspID, function(result) {
						if (result === "pass") {
							thisTest.PASS("The resource request "+passBehaviourText+" received by the server.");
						} else {
							thisTest.WARNING("The resource request "+failBehaviourText+" received by the server.");
						}
					});
				}, opts.timeout);
			});
		};
 
	var test_source = test_template.toString()
		.replace('iframe_src', '"'+iframe_src+'"')
		.replace('"+cspID', cspID+'"')
		.replace("opts.timeout", opts.timeout);

	// The test function currently contains the actual code necessary to check
	// whether the prerequisites (if any) are met; this code isn't very helpful to
	// the user for the purposes of test reporting, so replace it in toString()
	// with equivalent, friendlier code
	if (typeof prerequisiteMet === "undefined") {
		// If there are no prerequisites for this test, just remove the block
		// entirely
		var prerequisiteTemplate = "";
	} else {
		var prerequisiteTemplate = [];

		for (var p = 0; p < prerequisiteText.length; p++) {
			prerequisiteTemplate.push(
				"if (" + prerequisiteText[p] + ") {\n" +
				"thisTest.SKIP(\"" + prerequisiteSkipMessages[p] + "\");\n" +
				"}"
			);
		}

		prerequisiteTemplate = prerequisiteTemplate.join("\n").concat("\n\n");
	}
	test_source = test_source
		.replace(/^\s*\/\/ == BEGIN PREREQUISITE CHECKS ==[\S\s]*\/\/ == END PREREQUISITE CHECKS ==\n/m, prerequisiteTemplate)
		.replace('"+passBehaviourText+"', passBehaviourText)
		.replace('"+failBehaviourText+"', failBehaviourText);
	
	test_template.toString = function() { return test_source; };
	test_template.reportData = reportData;

	return test_template;
};

// Cross-Origin Resource Sharing -> Access-Control-Allow-Origin
var originExpect = function(testID, allowOrigin, shouldBeBlocked) {
	var urlstr = "https://test.browseraudit.com/cors/allow-origin/"+$.base64.encode(allowOrigin);
	
	// "none" is a special keyword indicating to the BA server that no
	// Access-Control-Allow-Origin HTTP header should be sent in the response
	var reportData = {};
	if (allowOrigin !== "none") {
		reportData.ajaxHTTPHeader = "Access-Control-Allow-Origin: " + allowOrigin;
	}

	var test_template = shouldBeBlocked ?
		function() {
			var thisTest = this;
			if (!Modernizr.cors) {
				thisTest.SKIP("The cross-origin resource sharing mechanism is not supported by this web browser.");
			}

			$.ajax({
				url: urlstr,
				success: function() {
					thisTest.WARNING("The cross-origin resource request was allowed.");
				},
				error: function(r, textStatus, errorThrown) {
					thisTest.PASS("The cross-origin resource request was blocked.");
				}
			});
		} : function() {
			var thisTest = this;
			if (!Modernizr.cors) {
				thisTest.SKIP("The cross-origin resource sharing mechanism is not supported by this web browser.");
			}

			$.ajax({
				url: urlstr,
				success: function() {
					thisTest.PASS("The cross-origin resource request was allowed.");
				},
				error: function(r, textStatus, errorThrown) {
					thisTest.WARNING("The cross-origin resource request was blocked.");
				}
			});
		};

	var test_source = test_template.toString()
		.replace('urlstr', '"'+urlstr+'"');
	test_template.toString = function() { return test_source; };
	test_template.reportData = reportData;

	return test_template;
};

// Cross-Origin Resource Sharing -> Access-Control-Allow-Methods
var methodExpect = function(testID, requestMethod, allowedMethods, shouldBeBlocked) {
	var urlstr = "https://test.browseraudit.com/cors/allow-methods/"+$.base64.encode(allowedMethods);
	
	// "none" is a special keyword indicating to the BA server that no
	// Access-Control-Allow-Methods HTTP header should be sent in the response
	var reportData = {};
	if (allowedMethods !== "none") {
		reportData.ajaxHTTPHeader = "Access-Control-Allow-Methods: " + allowedMethods;
	}
	
	var test_template = shouldBeBlocked ?
		function() {
			var thisTest = this;
			if (!Modernizr.cors) {
				thisTest.SKIP("The cross-origin resource sharing mechanism is not supported by this web browser.");
			}

			$.ajax({
				method: requestMethod,
				url: urlstr,
				success: function() {
					thisTest.WARNING("The cross-origin resource request was allowed.");
				},
				error: function(r, textStatus, errorThrown) {
					thisTest.PASS("The cross-origin resource request was blocked.");
				}
			});
		} : function() {
			var thisTest = this;
			if (!Modernizr.cors) {
				thisTest.SKIP("The cross-origin resource sharing mechanism is not supported by this web browser.");
			}

			$.ajax({
				method: requestMethod,
				url: urlstr,
				success: function() {
					thisTest.PASS("The cross-origin resource request was allowed.");
				},
				error: function(r, textStatus, errorThrown) {
					thisTest.WARNING("The cross-origin resource request was blocked.");
				}
			});
		};

	var test_source = test_template.toString()
		.replace('urlstr', '"'+urlstr+'"')
		.replace('requestMethod', '"'+requestMethod+'"');
	test_template.toString = function() { return test_source; };
	test_template.reportData = reportData;

	return test_template;
};

// Cross-Origin Resource Sharing -> Access-Control-Allow-Headers
var headersExpect = function(testID, requestHeaders, allowedHeaders, shouldBeBlocked) {
	var urlstr = "https://test.browseraudit.com/cors/allow-headers/"+$.base64.encode(allowedHeaders);

	// "none" is a special keyword indicating to the BA server that no
	// Access-Control-Allow-Headers HTTP header should be sent in the response
	var reportData = {};
	if (allowedHeaders !== "none") {
		reportData.ajaxHTTPHeader = "Access-Control-Allow-Headers: " + allowedHeaders;
	}
	
	var test_template = shouldBeBlocked ?
		function() {
			var thisTest = this;
			if (!Modernizr.cors) {
				thisTest.SKIP("The cross-origin resource sharing mechanism is not supported by this web browser.");
			}

			$.ajax({
				headers: requestHeaders,
				url: urlstr,
				success: function() {
					thisTest.WARNING("The cross-origin resource request was allowed.");
				},
				error: function(r, textStatus, errorThrown) {
					thisTest.PASS("The cross-origin resource request was blocked.");
				}
			});
		} : function() {
			var thisTest = this;
			if (!Modernizr.cors) {
				thisTest.SKIP("The cross-origin resource sharing mechanism is not supported by this web browser.");
			}

			$.ajax({
				headers: requestHeaders,
				url: urlstr,
				success: function() {
					thisTest.PASS("The cross-origin resource request was allowed.");
				},
				error: function(r, textStatus, errorThrown) {
					thisTest.WARNING("The cross-origin resource request was blocked.");
				}
			});
		};

	var test_source = test_template.toString()
		.replace('urlstr', '"'+urlstr+'"')
		.replace('requestHeaders', JSON.stringify(requestHeaders));
	test_template.toString = function() { return test_source; };
	test_template.reportData = reportData;

	return test_template;
}

// Cross-Origin Resource Sharing -> Access-Control-Expose-Headers
var exposeExpect = function(testID, responseHeader, exposedHeaders, shouldBeBlocked) {
	var urlstr = "https://test.browseraudit.com/cors/exposed-headers/"+$.base64.encode(exposedHeaders);
	
	// "none" is a special keyword indicating to the BA server that no
	// Access-Control-Expose-Headers HTTP header should be sent in the response
	var reportData = {};
	if (exposedHeaders !== "none") {
		reportData.ajaxHTTPHeader = "Access-Control-Expose-Headers: " + exposedHeaders;
	}
	
	var test_template = shouldBeBlocked ?
		function() {
			var thisTest = this;
			if (!Modernizr.cors) {
				thisTest.SKIP("The cross-origin resource sharing mechanism is not supported by this web browser.");
			}

			$.ajax({
				url: urlstr,
				success: function(data, textStatus, jqXHR) {
					if (jqXHR.getResponseHeader(responseHeader) === null) {
						thisTest.PASS("The "+responseHeader+" header was not exposed in the XMLHttpRequest response.");
					} else {
						thisTest.WARNING("The "+responseHeader+" header was exposed in the XMLHttpRequest response.");
					}
				},
				error: function(r, textStatus, errorThrown) {
					thisTest.SKIP("This test could not finish executing, possibly due to a network problem. Re-run the test suite to run this test again.");
				}
			});
		} : function() {
			var thisTest = this;
			if (!Modernizr.cors) {
				thisTest.SKIP("The cross-origin resource sharing mechanism is not supported by this web browser.");
			}

			$.ajax({
				url: urlstr,
				success: function(data, textStatus, jqXHR) {
					if (jqXHR.getResponseHeader(responseHeader) !== null) {
						thisTest.PASS("The "+responseHeader+" header was exposed in the XMLHttpRequest response.");
					} else {
						thisTest.WARNING("The "+responseHeader+" header was not exposed in the XMLHttpRequest response.");
					}
				},
				error: function(r, textStatus, errorThrown) {
					thisTest.SKIP("This test could not finish executing, possibly due to a network problem. Re-run the test suite to run this test again.");
				}
			});
		};

	var test_source = test_template.toString()
		.replace('urlstr','"'+urlstr+'"')
		.replace(/"\+responseHeader\+"/g, responseHeader)
		.replace('responseHeader','"'+responseHeader+'"');
	test_template.toString = function() { return test_source; };
	test_template.reportData = reportData;

	return test_template;
};

// Cookies -> HttpOnly flag -> HTTP-only cookie set by server and accessed from JavaScript
var cookiesHttpOnlyServerToScript = function(testID) {
	var test_template = function() {
		var thisTest = this;
    $.get("/httponly_cookie", function() {
      if (typeof $.cookie("httpOnlyCookie") === "undefined") {
				thisTest.PASS("The cookie could not be successfully accessed via JavaScript.");
			} else {
				thisTest.CRITICAL("The cookie was successfully accessed via JavaScript.");
			}
    });
  };

	test_template.reportData = {};
	return test_template;
};

// Cookies -> HttpOnly flag -> HTTP-only cookie set by JavaScript (should be discarded)
var cookiesHttpOnlyScriptDiscarded = function(testID) {
  var test_template = function() {
		var thisTest = this;
    // path and domain are set on the off-chance that the browser doesn't
    // discard this cookie, it is picked up by /clear_cookies for deletion
    document.cookie = "discard=browseraudit; HttpOnly; path=/; domain=.browseraudit.com";

		if (typeof $.cookie("discard") === "undefined") {
			thisTest.PASS("The cookie could not be successfully set via JavaScript.");
		} else {
			thisTest.CRITICAL("The cookie was successfully set via JavaScript.");
		}
  };

	test_template.reportData = {};
	return test_template;
};

// Cookies -> HttpOnly flag -> HTTP-only cookie set by JavaScript (should not be sent to server)
var cookiesHttpOnlyScriptToServer = function(testID) {
  var test_template = function() {
		var thisTest = this;
    // path and domain are set on the off-chance that the browser doesn't
    // discard this cookie, it is picked up by /clear_cookies for deletion
    document.cookie = "destroyMe=browseraudit; HttpOnly; path=/; domain=.browseraudit.com";

    $.get("/get_destroy_me", function(destroyMe) {
			if (destroyMe === "nil") {
				thisTest.PASS("The cookie was not sent to the server.");
			} else {
				thisTest.CRITICAL("The cookie was sent to the server.");
			}
    });
  };

	test_template.reportData = {};
	return test_template;
};

// Cookies -> Secure flag -> cookie set by server should be sent over HTTPS
var cookiesSecureServerToScriptHTTPS = function(testID) {
  var test_template = function() {
		var thisTest = this;
    $.get("/set_request_secure_cookie", function() {
      var secureCookie = $.cookie("requestSecureCookie");
      $.get("/get_request_secure_cookie", function(data) {
				if (data === secureCookie) {
					thisTest.PASS("The cookie was sent to the server.");
				} else {
					thisTest.CRITICAL("The cookie was not sent to the server.");
				}
      });
    });
  };

	test_template.reportData = {};
	return test_template;
};

// Cookies -> Secure flag -> cookie set by server should not be sent over HTTP
var cookiesSecureServerToScriptHTTP = function(testID) {
  var test_template = function() {
		var thisTest = this;
    $.get("/set_session_secure_cookie", function() {
      $("<img>", { src: "http://browseraudit.com/set_session_secure_cookie" }).load(function() {
        $.get("/get_session_secure_cookie", function(data) {
					if (data === "nil") {
						thisTest.PASS("The cookie was not sent to the server.");
					} else {
						thisTest.CRITICAL("The cookie was sent to the server.");
					}
        });
      });
    });
  };

	test_template.reportData = {};
	return test_template;
};

// Cookies -> Secure flag -> cookie set by JavaScript should be sent over HTTPS
var cookiesSecureScriptToServerHTTPS = function(testID) {
  var test_template = function() {
		var thisTest = this;
    $.cookie("requestSecureCookie", "227", { secure: true, path: "/", domain: ".browseraudit.com" });
    $.get("/get_request_secure_cookie", function(data) {
			if (data === "227") {
				thisTest.PASS("The cookie was sent to the server.");
			} else {
				thisTest.CRITICAL("The cookie was not sent to the server.");
			}
    });
  };

	test_template.reportData = {};
	return test_template;
};

// Cookies -> Secure flag -> cookie set by JavaScript should not be sent over HTTP
var cookiesSecureScriptToServerHTTP = function(testID) {
  var test_template = function() {
		var thisTest = this;
    $.cookie("sessionSecureCookie", "910", { secure: true, path: "/", domain: ".browseraudit.com" });
    $("<img>", { src: "http://browseraudit.com/set_session_secure_cookie" }).load(function() {
      $.get("/get_session_secure_cookie", function(data) {
				if (data === "nil") {
					thisTest.PASS("The cookie was not sent to the server.");
				} else {
					thisTest.CRITICAL("The cookie was sent to the server.");
				}
      });
    });
  };

	test_template.reportData = {};
	return test_template;
};

// Request Headers -> Referer -> should not be sent over non-secure request if the referring page was transferred with a secure protocol
var requestRefererHTTPSToHTTP = function(testID) {
  var test_template = function() {
		var thisTest = this;
    $("<img>", { src: "http://browseraudit.com/set_referer" }).load(function() {
      $.get("/get_referer", function(referer) {
				if (referer === "") {
					thisTest.PASS("The Referer header was not sent in the request.");
				} else {
					thisTest.WARNING("The Referer header was sent in the request.");
				}
      });
    });
  };

	test_template.reportData = {};
	return test_template;
};

// Response Headers -> X-Frame-Options
var frameOptionsTest = function(testID, shouldBeBlocked, sourcePrefix, frameOptions) {
	var defaultResult = (shouldBeBlocked) ? "pass" : "fail";
	var frameOptionsBase64 = $.base64.encode(frameOptions);
	var iframe_src = sourcePrefix+"/frameoptions/"+testID+"/"+defaultResult+"/"+frameOptionsBase64;
	
	var passBehaviourText = (shouldBeBlocked) ? "was not" : "was";
	var failBehaviourText = (shouldBeBlocked) ? "was" : "was not";

	var reportData = {
		iframeSrc: iframe_src.replace("https://test.","https://").concat("?serveOnly=true"),
		iframeHTTPHeader: "X-Frame-Options: " + frameOptions
	};

	var test_template = function() {
		var thisTest = this;
		$("<iframe>", { src: iframe_src }).appendTo("div#sandbox").load(function() {
			$.get("/frameoptions/result/"+testID, function(result) {
				if (result === "pass") {
					thisTest.PASS("The document "+passBehaviourText+" rendered.");
				} else {
					thisTest.WARNING("The document "+failBehaviourText+" rendered.");
				}
			});
		});
	};

	var test_source = test_template.toString()
		.replace('iframe_src', '"'+iframe_src+'"')
		.replace('"+testID', testID+'"')
		.replace('"+passBehaviourText+"', passBehaviourText)
		.replace('"+failBehaviourText+"', failBehaviourText);
	test_template.toString = function() { return test_source; };
	test_template.reportData = reportData;

	return test_template;
};

// Response Headers -> Strict-Transport-Security
var hstsTest = function(testID, hstsPolicy, headerOrigin, testOrigin, expectedProtocol, opts) {
	var base64Policy = $.base64.encode(hstsPolicy);

	var reportData = {
		firstImageHTTPHeader: "Strict-Transport-Security: " + hstsPolicy
	};

	var test_template = opts.setProtocolDelay ?
		function() {
			var thisTest = this;
			$("<img>", { src: headerOrigin+"/set_hsts/"+testID+"/"+base64Policy }).load(function() {
				setTimeout(function() {
					$("<img>", { src: testOrigin+"/set_protocol/"+testID }).load(function() {
						$.get("/get_protocol/"+testID, function(protocol) {
							// Clear effects of HSTS policy set by the Strict-Transport-Security
							// HTTP header earlier in the test
							$("<img>", { src: headerOrigin+"/clear_hsts/"+testID }).load(function() {
								if (protocol === expectedProtocol) {
									thisTest.PASS("The image was served using the "+expectedProtocol+" protocol.");
								} else {
									thisTest.WARNING("The image was not served using the "+expectedProtocol+" protocol.");
								}
							});
						});
					});
				}, opts.setProtocolDelay); // Wait for opts.setProtocolDelayms (HSTS expires after opts.hstsPeriodms)
			});
		} : function() {
			var thisTest = this;
			$("<img>", { src: headerOrigin+"/set_hsts/"+testID+"/"+base64Policy }).load(function() {
				$("<img>", { src: testOrigin+"/set_protocol/"+testID }).load(function() {
					$.get("/get_protocol/"+testID, function(protocol) {
						// Clear effects of HSTS policy set by the Strict-Transport-Security
						// HTTP header earlier in the test
						$("<img>", { src: headerOrigin+"/clear_hsts/"+testID }).load(function() {
							if (protocol === expectedProtocol) {
								thisTest.PASS("The image was served using the "+expectedProtocol+" protocol.");
							} else {
								thisTest.WARNING("The image was not served using the "+expectedProtocol+" protocol.");
							}
						});
					});
				});
			});
		};

	var test_source = test_template.toString()
		.replace(/headerOrigin\+"/g, '"'+headerOrigin)
		.replace('"+testID+"', testID)
		.replace(/"\+testID/g, testID+'"')
		.replace('"+base64Policy', base64Policy+'"')
		.replace('testOrigin+"', '"'+testOrigin)
		.replace(/"\+expectedProtocol\+"/g, expectedProtocol)
		.replace('expectedProtocol', '"'+expectedProtocol+'"');
	if (opts.setProtocolDelay) {
		test_source = test_source
			.replace(/opts\.setProtocolDelay/g, opts.setProtocolDelay)
			.replace('opts.hstsPeriod', opts.hstsPeriod);
	}
	test_template.toString = function() { return test_source; };
	test_template.reportData = reportData;

	return test_template;
};

