// Modernizr performs some feature detection tests asynchronously; this is a
// problem if we try to parse or execute test functions that test for the
// presence of these features before Modernizr has detected them, since it
// leads to JavaScript errors that prevent BrowserAudit from executing all
// desired tests or prevent the full test results from being displayed in the
// UI. We therefore wait for all of the asynchronous feature detection tests
// to execute before executing the BrowserAudit JavaScript code stored in the
// files at the paths defined by the argument to this function:
var browserAuditLoadDelayedScripts = function (scriptPaths) {
  // List of features detected asynchronously that are used by BrowserAudit
  // (note: don't list synchronously-detected features here, or execution of
  // readyCallback will be delayed unnecessarily):
  var asyncModernizrTests = ["flash"];

  // When all of the features listed in asyncModernizrTests have been detected,
  // load any remaining scripts that directly or indirectly rely on Modernizr's
  // feature detection being completed
  var loadScripts = function () {
    var nextScript = scriptPaths.shift();
    $.getScript(nextScript, function (data, status, xhr) {
      if (scriptPaths.length > 0) loadScripts();
    });
  };

  var asyncModernizrTestsExecuted = 0;
  $.each(asyncModernizrTests, function (i, testName) {
    Modernizr.on(testName, function () {
      if (++asyncModernizrTestsExecuted === asyncModernizrTests.length) loadScripts();
    });
  });
};
