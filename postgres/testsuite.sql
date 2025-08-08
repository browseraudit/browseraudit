--
-- PostgreSQL database dump: 29/07/2025 11:41
--

-- Dumped from database version 15.2
-- Dumped by pg_dump version 15.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: category; Type: TABLE DATA; Schema: public; Owner: browseraudit_user
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE public.category DISABLE TRIGGER ALL;

COPY public.category (id, parent, title, description, execute_order, live, in_default, short_description) FROM stdin;
3	1	DOM access - parent https://browseraudit.com, child https://test.browseraudit.com - child accessing parent	\N	2	t	t	\N
9	1	Cookies - illegal domain values	\N	8	t	t	\N
1	\N	Same-Origin Policy	<p>The same-origin policy (SOP) is arguably the most important principle in browser security. In this category, we test the browser's SOP implementation for DOM access, cookies, and requests     using the <em>XMLHttpRequest</em> API.</p>	1	t	t	Covers the browser's implementation of the <a href="https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy">same-origin policy</a>.
30	\N	Response Headers	<p>In this category, we test browser security features related to  miscellaneous HTTP response headers that do not fit into any other category.</p>	6	t	t	\N
35	11	connect-src	\N	10	t	t	\N
5	1	DOM access - parent https://test.browseraudit.com, child https://browseraudit.com - child accessing parent	\N	4	t	t	\N
6	1	DOM access - parent https://test.browseraudit.com, child https://browseraudit.com - parent accessing child	\N	5	t	t	\N
10	1	Cookies - path scope	<p>Whilst the <em>Domain</em> parameter of a cookie can be used to broaden its scope, the <em>Path</em> property can be used to <strong>restrict</strong> a cookie's scope. It specifies a path prefix, telling the browser to send the cookie only with requests matching that path. The paths are matched from the left, so a cookie with a path of <span class="tt">/user</span> will be sent with requests to both <span class="tt">/user/status</span> and <span class="tt">/user/account</span>. We test this behaviour below.</p>	9	t	t	\N
12	11	stylesheets	\N	1	t	t	\N
13	11	scripts	\N	2	t	t	\N
14	11	'unsafe-inline'	\N	3	t	t	\N
15	11	'unsafe-eval'	\N	4	t	t	\N
16	11	objects	\N	5	t	t	\N
25	\N	Cookies	<p>A lot of cookie security relates to the same-origin policy, and the setting of cookie scope through the <em>Domain</em> and <em>Path</em> attributes. This is covered in the <strong>Same-Origin Policy</strong> section. In this section, we are testing two other aspects of cookie security: the <em>HttpOnly</em> and <em>Secure</em> attributes. We test the behaviour of these attributes as defined in <a href="http://tools.ietf.org/html/rfc6265" target="_blank">RFC 6265</a> &ldquo;HTTP state management mechanism&rdquo; (Kristol, David M. and Lou Montulli, 2000).</p>	4	t	t	\N
8	1	Cookies - domain scope	<p>The same-origin policy for cookies defines when a browser should send a cookie with an HTTP request. Cookies often contain private and sensitive data, and so should only be sent with requests to the intended origin. The scope of a cookie (that is, the requests it will be sent with) can be broadened with the <em>Domain</em> parameter. It can be set to any fully-qualified right-hand segment of the qualified hostname, up to one level below the TLD. This means that a page at <span class="tt">payments.secure.example.com</span> may tell the browser to send a cookie to <span class="tt">*.secure.example.com</span> or <span class="tt">*.example.com</span> but not to <span class="tt">www.payments.secure.com</span> (since this is more specific than the page's current hostname) or <span class="tt">*.com</span> (since this is too broad).</p><p>We test that the browser's SOP for cookies behaves correctly when domain scope is set with the <em>Domain</em> parameter. We also test that illegal values are not allowed.</p>	7	t	t	\N
33	11	fonts	\N	9	t	t	\N
17	11	images	\N	6	t	t	\N
18	11	media	\N	7	t	t	\N
19	11	frames	\N	8	t	t	\N
21	20	Access-Control-Allow-Origin	\N	1	t	t	\N
22	20	Access-Control-Allow-Methods	\N	2	t	t	\N
23	20	Access-Control-Allow-Headers	\N	3	t	t	\N
24	20	Access-Control-Expose-Headers	\N	4	t	t	\N
4	1	DOM access - parent https://browseraudit.com, child https://test.browseraudit.com - parent accessing child	\N	3	t	t	\N
28	\N	Request Headers	<p>In this category, we test browser security features related to miscellaneous HTTP request headers that do not fit into any other category.</p>	5	t	t	\N
36	11	sandbox	<p>The "sandbox" directive enforces a sandbox policy on iframe elements. </p>	11	t	t	\N
37	11	Report-Only	<p>These tests check that no resources are blocked when the <span class="tt">Content-Security-Policy-Report-Only</span> header is used instead of <span class="tt">Content-Security-Policy</span>. We are not testing whether or not violation reports are sent &ndash; this is done in the report-uri category.</p>	13	f	t	\N
26	25	HttpOnly flag	<p>The <em>HttpOnly</em> attribute of a cookie instructs the browser to reveal that cookie only through an HTTP API. That is, the cookie may be transmitted to a server via an HTTP request, but should not be made available to client-side scripts. The benefit of this is that, even if a cross-site scripting (XSS) vulnerability is exploited, the cookie cannot be stolen.</p><p><em>HttpOnly</em> cookies are supported by all major browsers. </p><p>We have three tests. In the first test, we simply check that an <em>HttpOnly</em> cookie sent from the server cannot then be accessed by JavaScript. The latter two tests are testing that <em>HttpOnly</em> cookies cannot be created by JavaScript.</p>	1	t	t	\N
27	25	Secure flag	<p>When a cookie has the <em>Secure</em> attribute set, a compliant browser will include the cookie in an HTTP request only if the request is transmitted over a secure channel, i.e. an HTTPS request. This keeps the cookie confidential; an attacker would not be able to read it even if he were able to intercept the connection between the victim and the destination server.</p><p>The <em>Secure</em> flag is supported by all major browsers.</p><p>We have four tests, testing the behaviour of the <em>Secure</em> flag both when the cookies are set by the server and set by JavaScript. In each pair of tests, the first checks that a cookie with the <em>Secure</em> flag is sent to the server with an HTTPS request. The second test is the interesting one: it checks that a secure cookie is <strong>not</strong> sent with a request over plain HTTP. Browsers that support auto-upgrading mixed content should now pass these tests. </p>	2	t	t	\N
29	28	Referer	<p>The <span class="tt">Referer</span> header should not be included in a non-secure request if the referring page was transferred with a secure protocol. This behaviour is defined in <a href="https://tools.ietf.org/html/rfc2616" target="_blank">RFC 2616</a> &ldquo;Hypertext transfer protocol–HTTP/1.1&rdquo; (Fielding, Roy, et al., 1999). This behaviour exists because the source of a link might be private information or might reveal an otherwise private information source.</p><p>We test this behaviour by loading an image with a non-secure request and checking that the <span class="tt">Referer</span> header was not sent to the server with request for the image. If the browser supports auto-upgrading mixed content, then this test should pass. </p>	1	t	t	\N
34	11	report-uri	<p>These tests check that the browser sends a <span class="tt">POST</span> request to the server when the CSP is violated and a <span class="tt">report-uri</span> or  <span class="tt">report-to</span> has been specified in the header. Note that some anti-tracking browser addons may block these report requests. The browser should not follow any 3xx redirects when sending violation reports.</p>	12	t	t	\N
2	1	DOM access	<p>In all document object model (DOM) tests, we are always testing whether one page can access the DOM of another. In each test we refer to a parent and a child, where the child is an &lt;iframe&gt; inside the parent. When a parent accesses its child frame, it uses the <span class="tt">contentWindow</span> property. When a child frame accesses its parent, it does so with the <span class="tt">window.parent</span> property. In each test, one page tries to access the <span class="tt">document.location.protocol</span> property of the other. This is one of many properties for which access should be restricted by the same-origin policy.</p><p>DOM access should be denied by the browser whenever the origins of the two pages are different. An origin is usually a (scheme, host, port) tuple, except Internet Explorer doesn't compare the port when comparing two origins. The vast majority of the SOP for DOM tests below test cross-origin requests in which the hosts are different.</p><p>We previously tested that the <span class="tt">document.domain</span> can be used to loosen the same-origin policy restrictions. However, with new updates across browsers, this property is no longer used to loosen SOP restrictions. We test that attempts to loosen SOP with this technique is blocked by the browser.</p>	1	t	t	\N
20	\N	Cross-Origin Resource Sharing	<p>In this category of tests we test the browser's implementation of Cross-Origin Resource Sharing (CORS) as <a href="http://www.w3.org/TR/2014/REC-cors-20140116/">specified by the W3C</a> (Van Kesteren, Anne, 2014). CORS is an extension to the <em>XMLHttpRequest</em> API that allows a website to carry out cross-origin communications. This means that client-side JavaScript can send an <em>XMLHttpRequest</em> to a URL on a domain  (or scheme or port) other than the one from which it originated &ndash; something that is not otherwise possible due to the same-origin policy.</p><p>Cross-origin resource sharing allows a request to be made to a server at a different origin only if the server receiving the request explicitly allows it. That is, the server states whether or not the origin of the requesting document is allowed to make a cross-origin request to that URL. To achieve this, CORS defines a mechanism that allows the browser and server to know just enough about each other so that they can determine whether or not to allow the cross-origin request. This is primarily achieved by two key headers: an <span class="tt">Origin</span> header sent by the browser with the request, and an <span class="tt">Access-Control-Allow-Origin</span> header sent in the server's response. There are other CORS-related headers whose implementations we also test.</p>	3	t	t	Covers the browser's implementation of the <a href="http://www.w3.org/TR/2014/REC-cors-20140116/">Cross-Origin Resource Sharing</a> standard.
7	1	XMLHttpRequest	<p>The same-origin policy applies to the <em>XMLHttpRequest</em> API in a very similar manner to the DOM. That is, a client-side script may only make HTTP requests using the <em>XMLHttpRequest</em> API to the origin it originated from. The key difference when comparing the SOP for <em>XMLHttpRequest</em> to the SOP for DOM is that the <span class="tt">document.domain</span> property has no effect on origin checks for <em>XMLHttpRequest</em>. This means that it is impossible for two cooperating websites to agree for there to be cross-origin requests between them. </p><p>We test the SOP for the <em>XMLHttpRequest</em> API below. We check that requests are allowed when the origins match, and that they are blocked when either the host or scheme does not match. We don't currently test for differing ports.</p>	6	t	t	\N
31	30	X-Frame-Options	<p><span class="tt">X-Frame-Options</span> is a server-side technique that can be used to prevent clickjacking (UI redressing) attacks. Its implementation in current browsers is documented in <a href="http://tools.ietf.org/html/rfc7034" target="_blank">RFC 7034</a> &ldquo;HTTP Header Field X-Frame-Options&rdquo; (Ross, David, and Tobias Gondrom, 2013). <span class="tt">X-Frame-Options</span> is a response header that specifies whether or not the document being served is allowed to be rendered in a frame. More specifically, the header specifies the <strong>origin</strong> (scheme, host and port) that is allowed to render the document in a frame.</p><p>We test for correct behaviour of the <span class="tt">DENY</span> and <span class="tt">SAMEORIGIN</span>. Our tests use only <span class="tt">&lt;iframe&gt;</span>  and <span class="tt">&lt;frame&gt;</span> tags, although <span class="tt">X-Frame-Options</span> can also apply to <span class="tt">&lt;object&gt;</span>, <span class="tt">&lt;applet&gt;</span> (although this is now deprecated) and <span class="tt">&lt;embed&gt;</span> (which is discouraged to be used) tags.</p><p><span class="tt">X-Frame-Options</span> is supported in all modern browsers, although the implementations across browsers differ. Some browsers behave differently when dealing with nested frames, so we do not test these cases at all as there is no defined correct behaviour. Note that modern browsers no longer support the <span class="tt">ALLOW-FROM</span> directive, so we do not test this anymore.</p>	1	t	t	\N
11	\N	Content Security Policy	<p>In this category, we test that the browser correctly implements mechanisms from <a href="http://www.w3.org/TR/CSP/" target="_blank">Content Security Policy 1.0</a>, <a href="https://www.w3.org/TR/CSP2/" target="_blank">Content Security Policy 2.0</a> and <a href="http://www.w3.org/TR/CSP3/" target="_blank">Content Security Policy 3.0</a>. This means that we test the Content Security Policy (CSP) using only the <span class="tt">Content-Security-Policy</span> header, and not the <span class="tt">X-Content-Security-Policy</span> and <span class="tt">X-WebKit-CSP</span> headers used in experimental implementations in older browsers. A browser that implements the CSP using one of the latter two headers will fail many of the below tests.</p><p>The CSP is a mechanism used to mitigate cross-site scripting (XSS) attacks. It introduces the concept of <strong>source whitelists</strong>. A web developer can use the <span class="tt">Content-Security-Policy</span> header to explicitly specify the sources from which scripts, stylesheets and many other resources may be loaded. This can be done on a per-document basis by serving a different header value with each page.</p><p>We test a variety of origin mismatches for many resource types. At present, we only check origins that differ in host/domain. We do not test for origins that differ in scheme or port. A test referring to a &ldquo;remote&rdquo; resource is referring to a resource loaded from our subdomain <span class="tt">test.browseraudit.com</span>. A &ldquo;local&ldquo; resource is one loaded from the same origin as this page.</p><p>The number of tests executed below depends on your browser.</p>	2	t	t	Covers the browser's implementation of the <a href="https://www.w3.org/TR/2012/CR-CSP-20121115/">Content Security Policy 1.0</a>, <a href="https://www.w3.org/TR/CSP2/">2.0</a> and <a href="https://www.w3.org/TR/CSP3/">3.0</a>.
32	30	Strict-Transport-Security	<p>HTTP Strict Transport Security (HSTS) is a security mechanism that allows a server to instruct browsers only to communicate with it over a secure (HTTPS) connection for that domain. It exists primarily to defend against man-in-the-middle attacks in which an attacker is able to intercept his victim's network connection. The server sends this instruction with a <span class="tt">Strict-Transport-Security</span> header, defined in <a href="http://tools.ietf.org/html/rfc6797" target="_blank">RFC 6797</a> &ldquo;HTTP Strict Transport Security (HSTS)&rdquo; (Hodges, Jeff, Collin Jackson, and Adam Barth, 2012).</p><p>When HSTS is enabled on a domain, a compliant browser must rewrite any plain HTTP requests to that domain to use HTTPS. This includes both URLs entered into the navigation bar by the user, and elements loaded by a webpage. The <span class="tt">Strict-Transport-Security</span> header should only be sent in an HTTPS response. If the browser receives the header in a response sent over plain HTTP, it should be ignored.</p><p>We test the basic behaviour of HSTS and the <span class="tt">includeSubDomains</span> option. We also ensure that the header is ignored when transferred with an insecure protocol, and that the HSTS state correctly expires based on the <span class="tt">max-age</span> value. All of these tests work by testing whether a request for an image at <span class="tt">http://browseraudit.com/set_protocol</span> is rewritten to use HTTPS or not.</p>	2	t	t	Covers the browser's implementation of the <a href="https://developer.mozilla.org/en-US/docs/Web/Security/HTTP_strict_transport_security">HTTP Strict Transport Security</a> standard.
38	11	worker-src	\N	14	t	t	\N
39	11	manifest-src	\N	15	t	t	\N
40	28	Referrer-Policy	<p> These tests check whether the referer is sent or not sent depending on the options set out by the Referrer-Policy headers <p>	2	t	t	\N
41	11	form-action	\N	16	t	t	\N
42	11	frame-ancestors	\N	17	t	t	\N
43	20	Access-Control-Allow-Credentials	\N	5	t	t	\N
\.


ALTER TABLE public.category ENABLE TRIGGER ALL;

--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: browseraudit_user
--

ALTER TABLE public.test DISABLE TRIGGER ALL;

COPY public.test (id, title, timeout, behaviour, failure_severity, parent, execute_order, test_function, live) FROM stdin;
297	iframe from https://test.browseraudit.com with default-src 'self'	\N	block	warning	19	7	cspTest(297, 114, "default-src 'self'", true, {})	t
403	Child iframe changing location of parent iframe with sandbox allow-top-navigation	\N	allow	warning	36	21	cspTest(403, 228, "sandbox allow-same-origin allow-scripts allow-top-navigation", false, {})	f
406	report not received when report-uri is a redirect	300	block	warning	34	2	cspTest(406, 231, "default-src 'none'; report-uri /redirect/"+$.base64.encode("/csp/fail/231/emptyhtml?sessid="+$.cookie("sessid")), true, { timeout: 300 })	t
383	DOM access from child iframe on https://browseraudit.com to parent iframe on https://browseraudit.com with sandbox allow-same-origin	\N	allow	warning	36	1	cspTest(383, 200, "sandbox allow-same-origin allow-scripts", false, {})	t
328	@font-face from https://test.browseraudit.com in inline stylesheet with default-src 'none'	300	block	warning	33	18	cspTest(328, 145, "default-src 'none'; style-src 'unsafe-inline'", true, { timeout: 300 })	t
329	@font-face from https://test.browseraudit.com in inline stylesheet with default-src 'self'	300	block	warning	33	19	cspTest(329, 146, "default-src 'self'; style-src 'unsafe-inline'", true, { timeout: 300 })	t
207	script from https://browseraudit.com with default-src 'self'	\N	allow	warning	13	1	cspTest(207, 38, "default-src 'self'", false, {})	t
273	audio from https://browseraudit.com with media-src 'self'	\N	allow	warning	18	3	cspTest(273, 90, "default-src 'none'; media-src 'self'", false, {})	t
93	cookie for .browseraudit.org set by test.browseraudit.org is not sent to browseraudit.com	\N	block	critical	8	9	domainScopeCookieTest(93, true, "test.browseraudit.org", ".browseraudit.org", "browseraudit.com")	t
185	stylesheet from https://browseraudit.com with default-src 'self'	\N	allow	warning	12	1	cspTest(185, 1, "default-src 'self'", false, {})	t
307	frame from https://test.browseraudit.com with default-src 'self'	\N	block	warning	19	17	cspTest(307, 124, "default-src 'self'", true, {})	t
309	frame from https://test.browseraudit.com with frame-src 'none'	\N	block	warning	19	19	cspTest(309, 126, "default-src https://test.browseraudit.com; frame-src 'none'", true, {})	t
310	frame from https://test.browseraudit.com with frame-src 'self'	\N	block	warning	19	20	cspTest(310, 127, "default-src 'none'; frame-src 'self'", true, {})	t
313	@font-face from https://browseraudit.com in inline stylesheet with font-src 'self'	300	allow	warning	33	3	cspTest(313, 130, "default-src 'none'; style-src 'unsafe-inline'; font-src 'self'", false, { timeout: 300 })	t
333	@font-face from https://test.browseraudit.com in @import in inline stylesheet with default-src https://test.browseraudit.com	300	allow	warning	33	23	cspTest(333, 150, "default-src https://test.browseraudit.com; style-src 'self' 'unsafe-inline'", false, { timeout: 300 })	t
1	child https://browseraudit.com accessing parent https://browseraudit.org	\N	block	critical	2	1	parentChildSopTest(1, true, false, "https://browseraudit.org", "none", "https://browseraudit.com", "none")	t
186	stylesheet from https://browseraudit.com with default-src 'none'	\N	block	warning	12	2	cspTest(186, 2, "default-src 'none'", true, {})	t
5	child https://browseraudit.com accessing parent https://test.browseraudit.com	\N	block	critical	2	5	parentChildSopTest(5, true, false, "https://browseraudit.com", "none", "https://test.browseraudit.com", "none")	t
9	child https://browseraudit.com accessing parent https://test.browseraudit.org	\N	block	critical	2	9	parentChildSopTest(9, true, false, "https://test.browseraudit.org", "none", "https://browseraudit.com", "none")	t
12	parent https://test.browseraudit.org accessing child https://browseraudit.com	\N	block	critical	2	12	parentChildSopTest(12, true, true, "https://test.browseraudit.org", "none", "https://browseraudit.com", "none")	t
14	parent https://browseraudit.org accessing child https://test.browseraudit.com	\N	block	critical	2	14	parentChildSopTest(14, true, true, "https://browseraudit.org", "none", "https://test.browseraudit.com", "none")	t
187	stylesheet from https://browseraudit.com with style-src 'self'	\N	allow	warning	12	3	cspTest(187, 20, "default-src 'none'; style-src 'self'", false, {})	t
188	stylesheet from https://browseraudit.com with style-src 'none'	\N	block	warning	12	4	cspTest(188, 21, "default-src 'self'; style-src 'none'", true, {})	t
191	stylesheet @import from https://browseraudit.com with style-src 'self'	\N	allow	warning	12	7	cspTest(191, 32, "default-src 'none'; style-src 'unsafe-inline' 'self'", false, {})	t
193	stylesheet @import from file from https://browseraudit.com with default-src 'self'	\N	allow	warning	12	9	cspTest(193, 34, "default-src 'self'", false, {})	t
194	stylesheet @import from file from https://browseraudit.com with style-src 'self'	\N	allow	warning	12	10	cspTest(194, 36, "default-src 'none'; style-src 'self'", false, {})	t
196	stylesheet from https://test.browseraudit.com with default-src 'none'	\N	block	warning	12	12	cspTest(196, 23, "default-src 'none'", true, {})	t
197	stylesheet from https://test.browseraudit.com with default-src 'self	\N	block	warning	12	13	cspTest(197, 66, "default-src 'self'", true, {})	t
198	stylesheet from https://test.browseraudit.com with style-src https://test.browseraudit.com	\N	allow	warning	12	14	cspTest(198, 24, "default-src 'none'; style-src https://test.browseraudit.com", false, {})	t
210	script from https://browseraudit.com with script-src 'none'	\N	block	warning	13	4	cspTest(210, 41, "default-src 'self'; script-src 'none'", true, {})	t
212	script from https://test.browseraudit.com with default-src 'none'	\N	block	warning	13	6	cspTest(212, 43, "default-src 'none'", true, {})	t
215	script from https://test.browseraudit.com with script-src 'none'	\N	block	warning	13	9	cspTest(215, 45, "default-src https://test.browseraudit.com; script-src 'none'", true, {})	t
216	script from https://test.browseraudit.com with script-src 'self'	\N	block	warning	13	10	cspTest(216, 71, "default-src 'none'; script-src 'self'", true, {})	t
169	cookie set by JavaScript should be sent over HTTPS	\N	allow	critical	27	3	cookiesSecureScriptToServerHTTPS(169)	t
246	object from https://test.browseraudit.com with default-src 'none'	300	block	warning	16	6	cspTest(246, 61, "default-src 'none'", true, { timeout: 300 })	f
247	object from https://test.browseraudit.com with default-src 'self'	300	block	warning	16	7	cspTest(247, 64, "default-src 'self'", true, { timeout: 300 })	f
250	object from https://test.browseraudit.com with object-src 'self'	300	block	warning	16	10	cspTest(250, 65, "default-src 'none'; object-src 'self'", true, { timeout: 300 })	f
264	image from https://browseraudit.com with img-src 'none'	\N	block	warning	17	4	cspTest(264, 81, "default-src 'self'; img-src 'none'", true, {})	t
267	image from https://test.browseraudit.com with default-src 'self'	\N	block	warning	17	7	cspTest(267, 84, "default-src 'self'", true, {})	t
270	image from https://test.browseraudit.com with img-src 'self'	\N	block	warning	17	10	cspTest(270, 87, "default-src 'none'; img-src 'self'", true, {})	t
272	audio from https://browseraudit.com with default-src 'none'	\N	block	warning	18	2	cspTest(272, 89, "default-src 'none'", true, {})	t
276	audio from https://test.browseraudit.com with default-src 'none'	\N	block	warning	18	6	cspTest(276, 93, "default-src 'none'", true, {})	t
277	audio from https://test.browseraudit.com with default-src 'self'	\N	block	warning	18	7	cspTest(277, 94, "default-src 'self'", true, {})	t
280	audio from https://test.browseraudit.com with media-src 'self'	\N	block	warning	18	10	cspTest(280, 97, "default-src 'none'; media-src 'self'", true, {})	t
282	video from https://browseraudit.com with default-src 'none'	\N	block	warning	18	12	cspTest(282, 99, "default-src 'none'", true, {})	t
286	video from https://test.browseraudit.com with default-src 'none'	\N	block	warning	18	16	cspTest(286, 103, "default-src 'none'", true, {})	t
287	video from https://test.browseraudit.com with default-src 'self'	\N	block	warning	18	17	cspTest(287, 104, "default-src 'self'", true, {})	t
290	video from https://test.browseraudit.com with media-src 'self'	\N	block	warning	18	20	cspTest(290, 107, "default-src 'none'; media-src 'self'", true, {})	t
292	iframe from https://browseraudit.com with default-src 'none'	\N	block	warning	19	2	cspTest(292, 109, "default-src 'none'", true, {})	t
300	iframe from https://test.browseraudit.com with frame-src 'self'	\N	block	warning	19	10	cspTest(300, 117, "default-src 'none'; frame-src 'self'", true, {})	t
302	frame from https://browseraudit.com with default-src 'none'	\N	block	warning	19	12	cspTest(302, 119, "default-src 'none'", true, {})	t
304	frame from https://browseraudit.com with frame-src 'none'	\N	block	warning	19	14	cspTest(304, 121, "default-src 'self'; frame-src 'none'", true, {})	t
399	Submission of form via GET with sandbox allow-forms	300	allow	warning	36	17	cspTest(399, 224, "sandbox allow-scripts allow-forms", false, { timeout: 300 })	t
3	child https://browseraudit.org accessing parent https://browseraudit.com	\N	block	critical	2	3	parentChildSopTest(3, true, false, "https://browseraudit.com", "none", "https://browseraudit.org", "none")	t
4	parent https://browseraudit.org accessing child https://browseraudit.com	\N	block	critical	2	4	parentChildSopTest(4, true, true, "https://browseraudit.org", "none", "https://browseraudit.com", "none")	t
16	parent https://test.browseraudit.com accessing child https://browseraudit.org	\N	block	critical	2	16	parentChildSopTest(16, true, true, "https://test.browseraudit.com", "none", "https://browseraudit.org", "none")	t
21	child https://test.browseraudit.com accessing parent https://test.browseraudit.org	\N	block	critical	2	21	parentChildSopTest(21, true, false, "https://test.browseraudit.org", "none", "https://test.browseraudit.com", "none")	t
25	parent: document.domain not set, child: document.domain not set	\N	block	critical	3	1	parentChildSopTest(25, true, false, "https://browseraudit.com", "none", "https://test.browseraudit.com", "none")	t
28	parent: document.domain = "browseraudit.com", child: document.domain = "test.browseraudit.com"	\N	block	critical	3	4	parentChildSopTest(28, true, false, "https://browseraudit.com", "browseraudit.com", "https://test.browseraudit.com", "test.browseraudit.com")	t
32	parent: document.domain = "audit.com", child: document.domain = "audit.com"	\N	block	critical	3	8	parentChildSopTest(32, true, false, "https://browseraudit.com", "audit.com", "https://test.browseraudit.com", "audit.com")	t
69	https://test.browseraudit.com to https://test.browseraudit.org (host mismatch)	\N	block	critical	7	13	ajaxSopTest(69, true, "https://test.browseraudit.com", "https://test.browseraudit.org")	t
226	inline <script> with default-src 'none'	\N	block	warning	14	2	cspTest(226, 4, "default-src 'none'", true, {})	t
230	inline <style> with default-src 'none'	\N	block	warning	14	6	cspTest(230, 8, "default-src 'none'", true, {})	t
232	inline style attribute with default-src 'none'	\N	block	warning	14	8	cspTest(232, 10, "default-src 'none'", true, {})	t
236	eval()  without 'unsafe-eval'	\N	block	warning	15	4	cspTest(236, 14, "default-src 'unsafe-inline'", true, {})	t
266	image from https://test.browseraudit.com with default-src 'none'	\N	block	warning	17	6	cspTest(266, 83, "default-src 'none'", true, {})	t
296	iframe from https://test.browseraudit.com with default-src 'none'	\N	block	warning	19	6	cspTest(296, 113, "default-src 'none'", true, {})	t
314	@font-face from https://browseraudit.com in inline stylesheet with font-src 'none'	300	block	warning	33	4	cspTest(314, 131, "default-src 'self'; style-src 'unsafe-inline'; font-src 'none'", true, { timeout: 300 })	t
316	@font-face from https://browseraudit.com in @import in inline stylesheet with default-src 'none'	300	block	warning	33	6	cspTest(316, 133, "default-src 'none'; style-src 'self' 'unsafe-inline'", true, { timeout: 300 })	t
338	@font-face from https://test.browseraudit.com in @import in inline stylesheet with font-src 'self'	300	block	warning	33	28	cspTest(338, 155, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'self'", true, { timeout: 300 })	t
341	@font-face from https://test.browseraudit.com in stylesheet included via <link> with default-src 'self'	300	block	warning	33	31	cspTest(341, 158, "default-src 'self'; style-src 'self' 'unsafe-inline'", true, { timeout: 300 })	t
344	@font-face from https://test.browseraudit.com in stylesheet included via <link> with font-src 'self'	300	block	warning	33	34	cspTest(344, 161, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'self'", true, { timeout: 300 })	t
170	cookie set by JavaScript should not be sent over HTTP	\N	block	critical	27	4	cookiesSecureScriptToServerHTTP(170)	t
257	embed from https://test.browseraudit.com with default-src 'self'	300	block	warning	16	17	cspTest(257, 74, "default-src 'self'", true, { timeout: 300 })	f
405	report received with report-uri	300	block	warning	34	1	cspTest(405, 230, "default-src 'none'; report-uri /csp/pass/230/emptyhtml?sessid="+$.cookie("sessid"), false, { timeout: 300 })	t
345	@font-face from https://test.browseraudit.com in @import in stylesheet included via <link> with default-src https://test.browseraudit.com	300	allow	warning	33	35	cspTest(345, 162, "default-src https://test.browseraudit.com; style-src 'self' 'unsafe-inline'", false, { timeout: 300 })	t
347	@font-face from https://test.browseraudit.com in @import in stylesheet included via <link> with default-src 'self'	300	block	warning	33	37	cspTest(347, 164, "default-src 'self'; style-src 'self' 'unsafe-inline'", true, { timeout: 300 })	t
360	XMLHttpRequest.open() to https://test.browseraudit.com with connect-src 'self'	\N	block	warning	35	10	cspTest(360, 177, "connect-src 'none'; script-src 'unsafe-inline'; connect-src 'self'", true, {})	t
373	EventSource connecting to https://browseraudit.com with default-src 'self'	300	allow	warning	35	23	cspTest(373, 190, "default-src 'self'; script-src 'unsafe-inline'", false, { timeout: 300 })	t
375	EventSource connecting to https://browseraudit.com with connect-src 'self'	300	allow	warning	35	25	cspTest(375, 192, "default-src 'none'; script-src 'unsafe-inline'; connect-src 'self'", false, { timeout: 300 })	t
104	request to https://test.browseraudit.com with no Access-Control-Allow-Origin header	\N	block	warning	21	1	originExpect(104, "none", true)	t
137	Request with custom headers X-My-Header and X-Another-Header with Access-Control-Allow-Headers: X-Yet-Another-Header, X-My-Header, X-Another-Header	\N	allow	warning	23	14	headersExpect(137, {"X-My-Header": "foo", "X-Another-Header": "bar"}, "X-Yet-Another-Header, X-My-Header, X-Another-Header", false)	t
159	Caller can't access Date with no Access-Control-Expose-Headers header	\N	block	warning	24	22	exposeExpect(159, "Date", "none", true)	t
162	Caller can't access Date with Access-Control-Expose-Headers: Server	\N	block	warning	24	25	exposeExpect(162, "Date", "Server", true)	t
7	child https://test.browseraudit.com accessing parent https://browseraudit.com	\N	block	critical	2	7	parentChildSopTest(7, true, false, "https://browseraudit.com", "none", "https://test.browseraudit.com", "none")	t
34	parent: document.domain not set, child: document.domain = "browseraudit.com"	\N	block	critical	4	2	parentChildSopTest(34, true, true, "https://browseraudit.com", "none", "https://test.browseraudit.com", "browseraudit.com")	t
8	parent https://test.browseraudit.com accessing child https://browseraudit.com	\N	block	critical	2	8	parentChildSopTest(8, true, true, "https://test.browseraudit.com", "none", "https://browseraudit.com", "none")	t
13	child https://browseraudit.org accessing parent https://test.browseraudit.com	\N	block	critical	2	13	parentChildSopTest(13, true, false, "https://test.browseraudit.com", "none", "https://browseraudit.org", "none")	t
15	child https://test.browseraudit.com accessing parent https://browseraudit.org	\N	block	critical	2	15	parentChildSopTest(15, true, false, "https://browseraudit.org", "none", "https://test.browseraudit.com", "none")	t
18	parent https://browseraudit.org accessing child https://test.browseraudit.org	\N	block	critical	2	18	parentChildSopTest(18, true, true, "https://browseraudit.org", "none", "https://test.browseraudit.org", "none")	t
22	parent https://test.browseraudit.com accessing child https://test.browseraudit.org	\N	block	critical	2	22	parentChildSopTest(22, true, true, "https://test.browseraudit.com", "none", "https://test.browseraudit.org", "none")	t
26	parent: document.domain not set, child: document.domain = "browseraudit.com"	\N	block	critical	3	2	parentChildSopTest(26, true, false, "https://browseraudit.com", "none", "https://test.browseraudit.com", "browseraudit.com")	t
320	@font-face from https://browseraudit.com in stylesheet included via <link> with default-src 'none'	300	block	warning	33	10	cspTest(320, 137, "default-src 'none'; style-src 'self' 'unsafe-inline'", true, { timeout: 300 })	t
322	@font-face from https://browseraudit.com in stylesheet included via <link> with font-src 'none'	300	block	warning	33	12	cspTest(322, 139, "default-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'none'", true, { timeout: 300 })	t
326	@font-face from https://browseraudit.com in @import in stylesheet included via <link> with font-src 'none'	300	block	warning	33	16	cspTest(326, 143, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'none'", true, { timeout: 300 })	t
337	@font-face from https://test.browseraudit.com in @import in inline stylesheet with font-src 'none'	300	block	warning	33	27	cspTest(337, 154, "default-src https://test.browseraudit.com; style-src 'self' 'unsafe-inline'; font-src 'none'", true, { timeout: 300 })	t
352	XMLHttpRequest.open() to https://browseraudit.com with default-src 'none'	\N	block	warning	35	2	cspTest(352, 169, "default-src 'none'; script-src 'unsafe-inline'", true, {})	t
356	XMLHttpRequest.open() to https://test.browseraudit.com with default-src 'none'	\N	block	warning	35	6	cspTest(356, 173, "default-src 'none'; script-src 'unsafe-inline'", true, {})	t
357	XMLHttpRequest.open() to https://test.browseraudit.com with default-src 'self'	\N	block	warning	35	7	cspTest(357, 174, "default-src 'self'; script-src 'unsafe-inline'", true, {})	t
361	WebSocket connecting to wss://browseraudit.com with default-src 'self'	300	block	warning	35	11	cspTest(361, 178, "default-src 'self'; script-src 'unsafe-inline'", true, { timeout: 300 })	t
364	WebSocket connecting to wss://browseraudit.com with connect-src 'self'	300	block	warning	35	14	cspTest(364, 181, "default-src 'none'; script-src 'unsafe-inline'; connect-src 'self'", true, { timeout: 300 })	t
367	WebSocket connecting to wss://test.browseraudit.com with default-src 'self'	300	block	warning	35	17	cspTest(367, 184, "default-src 'self'; script-src 'unsafe-inline'", true, { timeout: 300 })	t
368	WebSocket connecting to wss://test.browseraudit.com with default-src 'none'	300	block	warning	35	18	cspTest(368, 185, "default-src 'none'; script-src 'unsafe-inline'", true, { timeout: 300 })	t
371	WebSocket connecting to wss://test.browseraudit.com with connect-src 'none'	300	block	warning	35	21	cspTest(371, 188, "default-src 'self'; script-src 'unsafe-inline'; connect-src 'none'", true, { timeout: 300 })	t
376	EventSource connecting to https://browseraudit.com with connect-src 'none'	300	block	warning	35	26	cspTest(376, 193, "default-src 'self'; script-src 'unsafe-inline'; connect-src 'none'", true, { timeout: 300 })	t
385	DOM access from child iframe on https://test.browseraudit.com to parent iframe on https://browseraudit.com with sandbox allow-same-origin	\N	block	warning	36	3	cspTest(385, 202, "sandbox allow-same-origin allow-scripts", true, {})	t
398	Script execution via onload event without sandbox allow-scripts	300	block	warning	36	16	cspTest(398, 223, "sandbox", true, { timeout: 300 })	t
121	Method OPTIONS with Access-Control-Allow-Methods: CONNECT	\N	block	warning	22	13	methodExpect(121, "OPTIONS", "CONNECT", true)	t
400	Submission of form via GET without sandbox allow-forms	300	block	warning	36	18	cspTest(400, 225, "sandbox allow-scripts", true, { timeout: 300 })	t
107	request to https://test.browseraudit.com with Access-Control-Allow-Origin: https://test.browseraudit.com	\N	block	warning	21	4	originExpect(107, "https://test.browseraudit.com", true)	t
127	Request with custom header X-My-Header with Access-Control-Allow-Headers: X-Another-Header, X-My-Header	\N	allow	warning	23	4	headersExpect(127, {"X-My-Header": "foo"}, "X-Another-Header, X-My-Header", false)	t
150	Caller can access Content-Length with Access-Control-Expose-Headers: Content-Length	\N	allow	warning	24	13	exposeExpect(150, "Content-Length", "Content-Length", false)	t
155	Caller can access Connection with Access-Control-Expose-Headers: Connection	\N	allow	warning	24	18	exposeExpect(155, "Connection", "Connection", false)	t
158	Caller can't access Connection with Access-Control-Expose-Headers: Server, Date	\N	block	warning	24	21	exposeExpect(158, "Connection", "Server, Date", true)	t
160	Caller can access Date with Access-Control-Expose-Headers: Date	\N	allow	warning	24	23	exposeExpect(160, "Date", "Date", false)	t
408	stylesheet from https://browseraudit.com with default-src 'none'	\N	allow	warning	37	2	cspTest(408, 215, "sandbox allow-scripts", true, {})	f
409	eval() with default-src 'unsafe-eval'	\N	allow	warning	37	3	cspTest(409, 216, "sandbox allow-same-origin allow-scripts", false, {})	f
33	parent: document.domain not set, child: document.domain not set	\N	block	critical	4	1	parentChildSopTest(33, true, true, "https://browseraudit.com", "none", "https://test.browseraudit.com", "none")	t
60	https://test.browseraudit.com to http://test.browseraudit.com (scheme mismatch)	\N	block	critical	7	4	ajaxSopTest(60, true, "https://test.browseraudit.com", "http://test.browseraudit.com")	t
168	cookie set by server should not be sent over HTTP	\N	block	critical	27	2	cookiesSecureServerToScriptHTTP(168)	t
57	https://browseraudit.com to https://browseraudit.com (allowed)	\N	allow	critical	7	1	ajaxSopTest(57, false, "https://browseraudit.com", "https://browseraudit.com")	t
71	https://browseraudit.org to https://test.browseraudit.org (host mismatch)	\N	block	critical	7	15	ajaxSopTest(71, true, "https://browseraudit.org", "https://test.browseraudit.org")	t
95	cookie for .test.browseraudit.org set by test.browseraudit.org is not sent to browseraudit.com	\N	block	critical	8	11	domainScopeCookieTest(95, true, "test.browseraudit.org", ".test.browseraudit.org", "browseraudit.com")	t
98	cookie for .com set by browseraudit.com is not sent to test.browseraudit.com (illegal parameter)	\N	block	critical	9	2	domainScopeCookieTest(98, true, "browseraudit.com", ".com", "test.browseraudit.com")	t
100	cookie for .com set by browseraudit.com is not sent to browseraudit.com (illegal parameter)	\N	block	critical	9	4	domainScopeCookieTest(100, true, "browseraudit.com", ".com", "browseraudit.com")	t
103	cookie with path /sop/path/ should not be sent to /sop/save_cookie/*	\N	block	critical	10	2	cookiePathScope(103, true, "soppathscope2")	t
209	script from https://browseraudit.com with script-src 'self'	\N	allow	warning	13	3	cspTest(209, 40, "default-src 'none'; script-src 'self'", false, {})	t
214	script from https://test.browseraudit.com with script-src https://test.browseraudit.com	\N	allow	warning	13	8	cspTest(214, 44, "default-src 'none'; script-src https://test.browseraudit.com", false, {})	t
221	SharedWorker from https://browseraudit.com with default-src 'self'	300	allow	warning	13	15	cspTest(221, 50, "default-src 'unsafe-inline' 'self'", false, { timeout: 300 })	t
225	inline <script> with default-src 'unsafe-inline'	\N	allow	warning	14	1	cspTest(225, 3, "default-src 'unsafe-inline'", false, {})	t
227	inline event handler with default-src 'unsafe-inline'	300	allow	warning	14	3	cspTest(227, 5, "default-src 'unsafe-inline'", false, { timeout: 300 })	t
231	inline style attribute with default-src 'unsafe-inline'	\N	allow	warning	14	7	cspTest(231, 9, "default-src 'self' 'unsafe-inline'", false, {})	t
237	setTimeout() with default-src 'unsafe-eval'	300	allow	warning	15	5	cspTest(237, 15, "default-src 'unsafe-inline' 'unsafe-eval'", false, { timeout: 300 })	t
238	setTimeout() without 'unsafe-eval'	300	block	warning	15	6	cspTest(238, 16, "default-src 'unsafe-inline'", true, { timeout: 300 })	t
72	https://test.browseraudit.org to https://test.browseraudit.org (host mismatch)	\N	block	critical	7	16	ajaxSopTest(72, true, "https://test.browseraudit.org", "https://test.browseraudit.org")	f
262	image from https://browseraudit.com with default-src 'none'	\N	block	warning	17	2	cspTest(262, 79, "default-src 'none'", true, {})	t
265	image from https://test.browseraudit.com with default-src https://test.browseraudit.com	\N	allow	warning	17	5	cspTest(265, 82, "default-src https://test.browseraudit.com", false, {})	t
271	audio from https://browseraudit.com with default-src 'self'	\N	allow	warning	18	1	cspTest(271, 88, "default-src 'self'", false, {})	t
37	parent: document.domain = "test.browseraudit.com", child: document.domain = "test.browseraudit.com"	\N	block	warning	4	5	parentChildSopTest(37, true, true, "https://browseraudit.com", "test.browseraudit.com", "https://test.browseraudit.com", "test.browseraudit.com")	t
42	parent: document.domain not set, child: document.domain = "browseraudit.com"	\N	block	warning	5	2	parentChildSopTest(42, true, false, "https://test.browseraudit.com", "none", "https://browseraudit.com", "browseraudit.com")	t
46	parent: document.domain = "browseraudit.com", child: document.domain = "browseraudit.com"	\N	allow	warning	5	6	parentChildSopTest(46, false, false, "https://test.browseraudit.com", "browseraudit.com", "https://browseraudit.com", "browseraudit.com")	f
52	parent: document.domain = "browseraudit.com", child: document.domain = "test.browseraudit.com"	\N	block	warning	6	4	parentChildSopTest(52, true, true, "https://test.browseraudit.com", "browseraudit.com", "https://browseraudit.com", "test.browseraudit.com")	t
172	iframe from same origin with SAMEORIGIN	\N	allow	warning	31	2	frameOptionsTest(172, false, "https://browseraudit.com", "SAMEORIGIN", true)	t
241	object from https://browseraudit.com with default-src 'self'	300	allow	warning	16	1	cspTest(241, 35, "default-src 'self'", false, { timeout: 300 })	f
248	object from https://test.browseraudit.com with object-src https://test.browseraudit.com	300	allow	warning	16	8	cspTest(248, 62, "default-src 'none'; object-src https://test.browseraudit.com", false, { timeout: 300 })	f
306	frame from https://test.browseraudit.com with default-src 'none'	\N	block	warning	19	16	cspTest(306, 123, "default-src 'none'", true, {})	t
387	XMLHttpRequest from child iframe on https://browseraudit.com to https://browseraudit.com with sandbox allow-same-origin	\N	allow	warning	36	5	cspTest(387, 204, "sandbox allow-same-origin allow-scripts", false, {})	t
109	Method PUT with Access-Control-Allow-Methods: PUT	\N	allow	warning	22	1	methodExpect(109, "PUT", "PUT", false)	t
410	eval() without 'unsafe-eval'	\N	allow	warning	37	4	cspTest(410, 217, "sandbox allow-scripts", true, {})	f
218	Worker from https://browseraudit.com with default-src 'none'	300	block	warning	13	12	cspTest(218, 47, "default-src 'unsafe-inline'", true, { timeout: 300 })	t
261	image from https://browseraudit.com with default-src 'self'	\N	allow	warning	17	1	cspTest(261, 78, "default-src 'self'", false, {})	t
275	audio from https://test.browseraudit.com with default-src https://test.browseraudit.com	\N	allow	warning	18	5	cspTest(275, 92, "default-src https://test.browseraudit.com", false, {})	t
281	video from https://browseraudit.com with default-src 'self'	\N	allow	warning	18	11	cspTest(281, 98, "default-src 'self'", false, {})	t
283	video from https://browseraudit.com with media-src 'self'	\N	allow	warning	18	13	cspTest(283, 100, "default-src 'none'; media-src 'self'", false, {})	t
285	video from https://test.browseraudit.com with default-src https://test.browseraudit.com	\N	allow	warning	18	15	cspTest(285, 102, "default-src https://test.browseraudit.com", false, {})	t
291	iframe from https://browseraudit.com with default-src 'self'	\N	allow	warning	19	1	cspTest(291, 108, "default-src 'self'", false, {})	t
293	iframe from https://browseraudit.com with frame-src 'self'	\N	allow	warning	19	3	cspTest(293, 110, "default-src 'none'; frame-src 'self'", false, {})	t
294	iframe from https://browseraudit.com with frame-src 'none'	\N	block	warning	19	4	cspTest(294, 111, "default-src 'self'; frame-src 'none'", true, {})	t
298	iframe from https://test.browseraudit.com with frame-src https://test.browseraudit.com	\N	allow	warning	19	8	cspTest(298, 115, "default-src 'none'; frame-src https://test.browseraudit.com", false, {})	t
301	frame from https://browseraudit.com with default-src 'self'	\N	allow	warning	19	11	cspTest(301, 118, "default-src 'self'", false, {})	t
305	frame from https://test.browseraudit.com with default-src https://test.browseraudit.com	\N	allow	warning	19	15	cspTest(305, 122, "default-src https://test.browseraudit.com", false, {})	t
311	@font-face from https://browseraudit.com in inline stylesheet with default-src 'self'	300	allow	warning	33	1	cspTest(311, 128, "default-src 'self'; style-src 'unsafe-inline'", false, { timeout: 300 })	t
349	@font-face from https://test.browseraudit.com in @import in stylesheet included via <link> with font-src 'none'	300	block	warning	33	39	cspTest(349, 166, "default-src https://test.browseraudit.com; style-src 'self' 'unsafe-inline'; font-src 'none'", true, { timeout: 300 })	t
379	EventSource connecting to https://test.browseraudit.com with default-src 'self'	300	block	warning	35	29	cspTest(379, 196, "default-src 'self'; script-src 'unsafe-inline'", true, { timeout: 300 })	t
381	EventSource connecting to https://test.browseraudit.com with connect-src 'none'	300	block	warning	35	31	cspTest(381, 198, "default-src 'self'; script-src 'unsafe-inline'; connect-src 'none'", true, { timeout: 300 })	t
388	XMLHttpRequest from child iframe on https://browseraudit.com to https://browseraudit.com without sandbox allow-same-origin	\N	block	warning	36	6	cspTest(388, 205, "sandbox allow-scripts", true, {})	t
389	XMLHttpRequest from child iframe on https://browseraudit.com to https://test.browseraudit.com with sandbox allow-same-origin	\N	block	warning	36	7	cspTest(389, 206, "sandbox allow-same-origin allow-scripts", true, {})	t
390	XMLHttpRequest from child iframe on https://browseraudit.com to https://test.browseraudit.com without sandbox allow-same-origin	\N	block	warning	36	8	cspTest(390, 207, "sandbox allow-scripts", true, {})	t
396	Script execution via <script> element without sandbox allow-scripts	\N	block	warning	36	14	cspTest(396, 221, "sandbox", true, {})	t
105	request to https://test.browseraudit.com with Access-Control-Allow-Origin: https://browseraudit.com	\N	allow	warning	21	2	originExpect(105, "https://browseraudit.com", false)	t
106	request to https://test.browseraudit.com with Access-Control-Allow-Origin: *	\N	allow	warning	21	3	originExpect(106, "*", false)	t
108	request to https://test.browseraudit.com with Access-Control-Allow-Origin: https://browseraudit.org	\N	block	warning	21	5	originExpect(108, "https://browseraudit.org", true)	t
110	Method PUT with Access-Control-Allow-Methods: DELETE, PUT	\N	allow	warning	22	2	methodExpect(110, "PUT", "DELETE, PUT", false)	t
114	Method DELETE with Access-Control-Allow-Methods: DELETE	\N	allow	warning	22	6	methodExpect(114, "DELETE", "DELETE", false)	t
119	Method OPTIONS with Access-Control-Allow-Methods: OPTIONS	\N	allow	warning	22	11	methodExpect(119, "OPTIONS", "OPTIONS", false)	t
120	Method OPTIONS with Access-Control-Allow-Methods: CONNECT, OPTIONS	\N	allow	warning	22	12	methodExpect(120, "OPTIONS", "CONNECT, OPTIONS")	t
143	Caller can access Pragma with no Access-Control-Expose-Headers header	\N	allow	warning	24	6	exposeExpect(143, "Pragma", "none", false)	t
145	Caller can access Server with Access-Control-Expose-Headers: Server	\N	allow	warning	24	8	exposeExpect(145, "Server", "Server", false)	t
179	browser should not send further requests over plain (non-secure) HTTP	\N	block	warning	32	1	hstsTest(179, "max-age=2", "https://browseraudit.com", "http://browseraudit.com", "https", {})	t
182	should be ignored if sent over plain HTTP	\N	allow	warning	32	4	hstsTest(182, "max-age=2", "http://browseraudit.com", "http://browseraudit.com", "http", {})	t
43	parent: document.domain = "browseraudit.com", child: document.domain not set	\N	block	warning	5	3	parentChildSopTest(43, true, false, "https://test.browseraudit.com", "browseraudit.com", "https://browseraudit.com", "none")	t
47	parent: document.domain = "browseraudit.com", child: document.domain = "browseraudit.com"	\N	allow	warning	5	7	parentChildSopTest(47, false, false, "https://test.browseraudit.com", "browseraudit.com", "https://browseraudit.com", "browseraudit.com")	f
253	embed from https://browseraudit.com with object-src 'self'	300	allow	warning	16	13	cspTest(253, 58, "default-src 'none'; object-src 'self'", false, { timeout: 300 })	f
319	@font-face from https://browseraudit.com in stylesheet included via <link> with default-src 'self'	300	allow	warning	33	9	cspTest(319, 136, "default-src 'self'; style-src 'self' 'unsafe-inline'", false, { timeout: 300 })	t
321	@font-face from https://browseraudit.com in stylesheet included via <link> with font-src 'self'	300	allow	warning	33	11	cspTest(321, 138, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'self'", false, { timeout: 300 })	t
58	https://test.browseraudit.com to https://test.browseraudit.com (allowed)	\N	allow	critical	7	2	ajaxSopTest(58, false, "https://test.browseraudit.com", "https://test.browseraudit.com")	t
62	https://test.browseraudit.com to https://browseraudit.com (host mismatch)	\N	block	critical	7	6	ajaxSopTest(62, true, "https://test.browseraudit.com", "https://browseraudit.com")	t
64	https://browseraudit.org to https://browseraudit.com (host mismatch)	\N	block	critical	7	8	ajaxSopTest(64, true, "https://browseraudit.org", "https://browseraudit.com")	t
67	https://test.browseraudit.com to https://browseraudit.org (host mismatch)	\N	block	critical	7	11	ajaxSopTest(67, true, "https://test.browseraudit.com", "https://browseraudit.org")	t
70	https://test.browseraudit.org to https://test.browseraudit.com (host mismatch)	\N	block	critical	7	14	ajaxSopTest(70, true, "https://test.browseraudit.org", "https://test.browseraudit.com")	t
86	cookie for .browseraudit.com set by browseraudit.com is sent to test.browseraudit.com	\N	allow	critical	8	2	domainScopeCookieTest(86, false, "browseraudit.com", ".browseraudit.com", "test.browseraudit.com")	t
88	cookie for .browseraudit.com set by test.browseraudit.com is sent to test.browseraudit.com	\N	allow	critical	8	4	domainScopeCookieTest(88, false, "test.browseraudit.com", ".browseraudit.com", "test.browseraudit.com")	t
91	cookie for .browseraudit.org set by browseraudit.org is not sent to browseraudit.com	\N	block	critical	8	7	domainScopeCookieTest(91, true, "browseraudit.org", ".browseraudit.org", "browseraudit.com")	t
200	stylesheet from https://test.browseraudit.com with style-src 'self'	\N	block	warning	12	16	cspTest(200, 67, "default-src 'none'; style-src 'self'", true, {})	t
201	stylesheet @import from https://test.browseraudit.com with default-src https://test.browseraudit.com	\N	allow	warning	12	17	cspTest(201, 26, "default-src 'unsafe-inline' https://test.browseraudit.com", false, {})	t
202	stylesheet @import from https://test.browseraudit.com with default-src 'none'	\N	block	warning	12	18	cspTest(202, 27, "default-src 'unsafe-inline'", true, {})	t
203	stylesheet @import from https://test.browseraudit.com with default-src 'self'	\N	block	warning	12	19	cspTest(203, 68, "default-src 'self' 'unsafe-inline'", true, {})	t
332	@font-face from https://test.browseraudit.com in inline stylesheet with font-src 'self'	300	block	warning	33	22	cspTest(332, 149, "default-src 'none'; style-src 'unsafe-inline'; font-src 'self'", true, { timeout: 300 })	t
99	cookie for .com set by test.browseraudit.com is not sent to test.browseraudit.com (illegal parameter)	\N	block	critical	9	3	domainScopeCookieTest(99, true, "test.browseraudit.com", ".com", "test.browseraudit.com")	t
189	stylesheet @import from https://browseraudit.com with default-src 'self'	\N	allow	warning	12	5	cspTest(189, 30, "default-src 'unsafe-inline' 'self'", false, {})	t
204	stylesheet @import from https://test.browseraudit.com with style-src https://test.browseraudit.com	\N	allow	warning	12	20	cspTest(204, 28, "default-src 'none'; style-src 'unsafe-inline' https://test.browseraudit.com", false, {})	t
205	stylesheet @import from https://test.browseraudit.com with style-src 'none'	\N	block	warning	12	21	cspTest(205, 29, "default-src none'; style-src 'unsafe-inline'", true, {})	t
208	script from https://browseraudit.com with default-src 'none'	\N	block	warning	13	2	cspTest(208, 39, "default-src 'none'", true, {})	t
217	Worker from https://browseraudit.com with default-src 'self'	300	allow	warning	13	11	cspTest(217, 46, "default-src 'unsafe-inline' 'self'", false, { timeout: 300 })	t
235	eval() with default-src 'unsafe-eval'	\N	allow	warning	15	3	cspTest(235, 13, "default-src 'unsafe-inline' 'unsafe-eval'", false, {})	t
317	@font-face from https://browseraudit.com in @import in inline stylesheet with font-src 'self'	300	allow	warning	33	7	cspTest(317, 134, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'self'", false, { timeout: 300 })	t
323	@font-face from https://browseraudit.com in @import in stylesheet included via <link> with default-src 'self'	300	allow	warning	33	13	cspTest(323, 140, "default-src 'self'; style-src 'self' 'unsafe-inline'", false, { timeout: 300 })	t
327	@font-face from https://test.browseraudit.com in inline stylesheet with default-src https://test.browseraudit.com	300	allow	warning	33	17	cspTest(327, 144, "default-src https://test.browseraudit.com; style-src 'unsafe-inline'", false, { timeout: 300 })	t
331	@font-face from https://test.browseraudit.com in inline stylesheet with font-src 'none'	300	block	warning	33	21	cspTest(331, 148, "default-src https://test.browseraudit.com; style-src 'unsafe-inline'; font-src 'none'", true, { timeout: 300 })	t
339	@font-face from https://test.browseraudit.com in stylesheet included via <link> with default-src https://test.browseraudit.com	300	allow	warning	33	29	cspTest(339, 156, "default-src https://test.browseraudit.com; style-src 'self' 'unsafe-inline'", false, { timeout: 300 })	t
342	@font-face from https://test.browseraudit.com in stylesheet included via <link> with font-src https://test.browseraudit.com	300	allow	warning	33	32	cspTest(342, 159, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src https://test.browseraudit.com", false, { timeout: 300 })	t
54	parent: document.domain = "browseraudit.com", child: document.domain = "browseraudit.com"	\N	allow	warning	6	6	parentChildSopTest(54, false, true, "https://test.browseraudit.com", "browseraudit.com", "https://browseraudit.com", "browseraudit.com")	f
56	parent: document.domain = "audit.com", child: document.domain = "audit.com"	\N	block	warning	6	8	parentChildSopTest(56, true, true, "https://test.browseraudit.com", "audit.com", "https://browseraudit.com", "audit.com")	t
242	object from https://browseraudit.com with default-src 'none'	300	block	warning	16	2	cspTest(242, 37, "default-src 'none'", true, { timeout: 300 })	f
251	embed from https://browseraudit.com with default-src 'self'	300	allow	warning	16	11	cspTest(251, 56, "default-src 'self'", false, { timeout: 300 })	f
351	XMLHttpRequest.open() to https://browseraudit.com with default-src 'self'	\N	allow	warning	35	1	cspTest(351, 168, "default-src 'self'; script-src 'unsafe-inline'", false, {})	t
353	XMLHttpRequest.open() to https://browseraudit.com with connect-src 'self'	\N	allow	warning	35	3	cspTest(353, 170, "default-src 'none'; script-src 'unsafe-inline'; connect-src 'self'", false, {})	t
391	Access from child iframe on https://browseraudit.com to cookie on .browseraudit.com with sandbox allow-same-origin	\N	allow	warning	36	9	cspTest(391, 208, "sandbox allow-same-origin allow-scripts", false, {})	t
392	Access from child iframe on https://browseraudit.com to cookie on .browseraudit.com without sandbox allow-same-origin	\N	block	warning	36	10	cspTest(392, 209, "sandbox allow-scripts", true, {})	t
402	Submission of form via POST without sandbox allow-forms	300	block	warning	36	20	cspTest(402, 227, "sandbox allow-scripts", true, { timeout: 300 })	t
111	Method PUT with Access-Control-Allow-Methods: DELETE	\N	block	warning	22	3	methodExpect(111, "PUT", "DELETE", true)	t
116	Method DELETE with Access-Control-Allow-Methods: TRACE	\N	block	warning	22	8	methodExpect(116, "DELETE", "TRACE", true)	t
117	Method DELETE with Access-Control-Allow-Methods: TRACE, OPTIONS	\N	block	warning	22	9	methodExpect(117, "DELETE", "TRACE, OPTIONS", true)	t
123	Method OPTIONS with no Access-Control-Allow-Methods header	\N	block	warning	22	15	methodExpect(123, "OPTIONS", "none", true)	t
128	Request with custom header X-My-Header with Access-Control-Allow-Headers: X-Another-Header, X-Yet-Another-Header	\N	block	warning	23	5	headersExpect(128, {"X-My-Header": "foo"}, "X-Another-Header, X-Yet-Another-Header", true)	t
133	Request with custom headers X-My-Header and X-Another-Header with Access-Control-Allow-Headers: X-My-Header, X-Yet-Another-Header	\N	block	warning	23	10	headersExpect(133, {"X-My-Header": "foo", "X-Another-Header": "bar"}, "X-My-Header, X-Yet-Another-Header", true)	t
142	Caller can access Last-Modified with no Access-Control-Expose-Headers header	\N	allow	warning	24	5	exposeExpect(142, "Last-Modified", "none", false)	t
146	Caller can access Server with Access-Control-Expose-Headers: Content-Length, Server	\N	allow	warning	24	9	exposeExpect(146, "Server", "Content-Length, Server", false)	t
161	Caller can access Date with Access-Control-Expose-Headers: Server, Date	\N	allow	warning	24	24	exposeExpect(161, "Date", "Server, Date", false)	t
163	Caller can't access Date with Access-Control-Expose-Headers: Content-Length, Server	\N	block	warning	24	26	exposeExpect(163, "Date", "Content-Length, Server", true)	t
167	cookie set by server should be sent over HTTPS	\N	allow	critical	27	1	cookiesSecureServerToScriptHTTPS(167)	t
184	should not be sent over non-secure request if the referring page was transferred with a secure protocol	\N	block	warning	29	1	requestRefererHTTPSToHTTP(184)	t
404	Child iframe changing location of parent iframe without sandbox allow-top-navigation	\N	block	warning	36	22	cspTest(404, 229, "sandbox allow-same-origin allow-scripts", true, {})	f
2	parent https://browseraudit.com accessing child https://browseraudit.org	\N	block	critical	2	2	parentChildSopTest(2, true, true, "https://browseraudit.com", "none", "https://browseraudit.org", "none")	t
6	parent https://browseraudit.com accessing child https://test.browseraudit.com	\N	block	critical	2	6	parentChildSopTest(6, true, true, "https://browseraudit.com", "none", "https://test.browseraudit.com", "none")	t
10	parent https://browseraudit.com accessing child https://test.browseraudit.org	\N	block	critical	2	10	parentChildSopTest(10, true, true, "https://browseraudit.com", "none", "https://test.browseraudit.org", "none")	t
11	child https://test.browseraudit.org accessing parent https://browseraudit.com	\N	block	critical	2	11	parentChildSopTest(11, true, false, "https://browseraudit.com", "none", "https://test.browseraudit.org", "none")	t
61	https://browseraudit.com to https://test.browseraudit.com (host mismatch)	\N	block	critical	7	5	ajaxSopTest(61, true, "https://browseraudit.com", "https://test.browseraudit.com")	t
63	https://browseraudit.com to https://browseraudit.org (host mismatch)	\N	block	critical	7	7	ajaxSopTest(63, true, "https://browseraudit.com", "https://browseraudit.org")	t
65	https://browseraudit.com to https://test.browseraudit.org (host mismatch)	\N	block	critical	7	9	ajaxSopTest(65, true, "https://browseraudit.com", "https://test.browseraudit.org")	t
89	cookie for .test.browseraudit.com is sent to test.browseraudit.com	\N	allow	critical	8	5	domainScopeCookieTest(89, true, "test.browseraudit.com", ".test.browseraudit.com", "browseraudit.com")	t
92	cookie for .browseraudit.org set by browseraudit.org is not sent to test.browseraudit.com	\N	block	critical	8	8	domainScopeCookieTest(92, true, "browseraudit.org", ".browseraudit.org", "test.browseraudit.com")	t
102	cookie with path /sop/path/ should be sent to /sop/path/save_cookie/*	\N	allow	critical	10	1	cookiePathScope(102, false, "soppathscope1")	t
222	SharedWorker from https://browseraudit.com with default-src 'none'	300	block	warning	13	16	cspTest(222, 51, "default-src 'unsafe-inline'", true, { timeout: 300 })	t
334	@font-face from https://test.browseraudit.com in @import in inline stylesheet with default-src 'none'	300	block	warning	33	24	cspTest(334, 151, "default-src 'none'; style-src 'self' 'unsafe-inline'", true, { timeout: 300 })	t
369	WebSocket connecting to wss://test.browseraudit.com with default-src wss://test.browseraudit.com	300	allow	warning	35	19	cspTest(369, 186, "default-src wss://test.browseraudit.com; script-src 'unsafe-inline'", false, { timeout: 300 })	t
378	EventSource connecting to https://test.browseraudit.com with default-src 'none'	300	block	warning	35	28	cspTest(378, 195, "default-src 'none'; script-src 'unsafe-inline'", true, { timeout: 300 })	t
395	Script execution via <script> element with sandbox allow-scripts	\N	allow	warning	36	13	cspTest(395, 220, "sandbox allow-scripts", false, {})	t
112	Method PUT with Access-Control-Allow-Methods: DELETE, TRACE	\N	block	warning	22	4	methodExpect(112, "PUT", "DELETE, TRACE", true)	t
113	Method PUT with no Access-Control-Allow-Methods header	\N	block	warning	22	5	methodExpect(113, "PUT", "none", true)	t
118	Method DELETE with no Access-Control-Allow-Methods header	\N	block	warning	22	10	methodExpect(118, "DELETE", "none", true)	t
177	iframe from remote origin with ALLOW-FROM test.browseraudit.com	\N	block	warning	31	7	frameOptionsTest(177, true, "https://test.browseraudit.com", "ALLOW-FROM https://test.browseraudit.com", true)	f
124	Request with custom header X-My-Header with no Access-Control-Allow-Headers header present	\N	block	warning	23	1	headersExpect(124, {"X-My-Header": "foo"}, "none", true)	t
130	Request with custom headers X-My-Header and X-Another-Header with Access-Control-Allow-Headers: X-My-Header	\N	block	warning	23	7	headersExpect(130, {"X-My-Header": "foo", "X-Another-Header": "bar"}, "X-My-Header", true)	t
134	Request with custom headers X-My-Header and X-Another-Header with Access-Control-Allow-Headers: X-Yet-Another-Header, X-Another-Header	\N	block	warning	23	11	headersExpect(134, {"X-My-Header": "foo", "X-Another-Header": "bar"}, "X-Yet-Another-Header, X-Another-Header", true)	t
135	Request with custom headers X-My-Header and X-Another-Header with Access-Control-Allow-Headers: X-Yet-Another-Header, X-Custom-Header	\N	block	warning	23	12	headersExpect(135, {"X-My-Header": "foo", "X-Another-Header": "bar"}, "X-Yet-Another-Header, X-Custom-Header", true)	t
138	Caller can access Cache-Control with no Access-Control-Expose-Headers header	\N	allow	warning	24	1	exposeExpect(138, "Cache-Control", "none", false)	t
140	Caller can access Content-Type with no Access-Control-Expose-Headers header	\N	allow	warning	24	3	exposeExpect(140, "Content-Type", "none", false)	t
141	Caller can access Expires with no Access-Control-Expose-Headers header	\N	allow	warning	24	4	exposeExpect(141, "Expires", "none", false)	t
147	Caller can't access Server with Access-Control-Expose-Headers: Content-Length	\N	block	warning	24	10	exposeExpect(147, "Server", "Content-Length", true)	t
149	Caller can't access Content-Length with no Access-Control-Expose-Headers header	\N	block	warning	24	12	exposeExpect(149, "Content-Length", "none", true)	t
152	Caller can't access Content-Length with Access-Control-Expose-Headers: Connection	\N	block	warning	24	15	exposeExpect(152, "Content-Length", "Connection", true)	t
154	Caller can't access Connection with no Access-Control-Expose-Headers header	\N	block	warning	24	17	exposeExpect(154, "Connection", "none", true)	t
157	Caller can't access Connection with Access-Control-Expose-Headers: Date	\N	block	warning	24	20	exposeExpect(157, "Connection", "Date", true)	t
164	HTTP-only cookie set by server and accessed from JavaScript	\N	block	critical	26	1	cookiesHttpOnlyServerToScript(164)	t
165	HTTP-only cookie set by JavaScript (should be discarded)	\N	block	critical	26	2	cookiesHttpOnlyScriptDiscarded(165)	t
166	HTTP-only cookie set by JavaScript (should not be sent to server)	\N	block	critical	26	3	cookiesHttpOnlyScriptToServer(166)	t
17	child https://browseraudit.org accessing parent https://test.browseraudit.org	\N	block	critical	2	17	parentChildSopTest(17, true, false, "https://test.browseraudit.org", "none", "https://browseraudit.org", "none")	t
19	child https://test.browseraudit.org accessing parent https://browseraudit.org	\N	block	critical	2	19	parentChildSopTest(19, true, false, "https://browseraudit.org", "none", "https://test.browseraudit.org", "none")	t
20	parent https://test.browseraudit.org accessing child https://browseraudit.org	\N	block	critical	2	20	parentChildSopTest(20, true, true, "https://test.browseraudit.org", "none", "https://browseraudit.org", "none")	t
23	child https://test.browseraudit.org accessing parent https://test.browseraudit.com	\N	block	critical	2	23	parentChildSopTest(23, true, false, "https://test.browseraudit.com", "none", "https://test.browseraudit.org", "none")	t
24	parent https://test.browseraudit.org accessing child https://test.browseraudit.com	\N	block	critical	2	24	parentChildSopTest(24, true, true, "https://test.browseraudit.org", "none", "https://test.browseraudit.com", "none")	t
27	parent: document.domain = "browseraudit.com", child: document.domain not set	\N	block	critical	3	3	parentChildSopTest(27, true, false, "https://browseraudit.com", "browseraudit.com", "https://test.browseraudit.com", "none")	t
29	parent: document.domain = "test.browseraudit.com", child: document.domain = "test.browseraudit.com"	\N	block	critical	3	5	parentChildSopTest(29, true, false, "https://browseraudit.com", "test.browseraudit.com", "https://test.browseraudit.com", "test.browseraudit.com")	t
59	https://browseraudit.com to http://browseraudit.com (scheme mismatch)	\N	block	critical	7	3	ajaxSopTest(59, true, "https://browseraudit.com", "http://browseraudit.com")	t
31	parent: document.domain = "test.browseraudit.com", child: document.domain = "browseraudit.com"	\N	allow	warning	3	7	parentChildSopTest(31, true, false, "https://browseraudit.com", "test.browseraudit.com", "https://test.browseraudit.com", "browseraudit.com")	f
39	parent: document.domain = "browseraudit.com", child: document.domain = "browseraudit.com"	\N	allow	warning	4	7	parentChildSopTest(39, false, true, "https://browseraudit.com", "browseraudit.com", "https://test.browseraudit.com", "browseraudit.com")	f
40	parent: document.domain = "audit.com", child: document.domain = "audit.com"	\N	block	warning	4	8	parentChildSopTest(40, true, true, "https://browseraudit.com", "audit.com", "https://test.browseraudit.com", "audit.com")	t
41	parent: document.domain not set, child: document.domain not set	\N	block	warning	5	1	parentChildSopTest(41, true, false, "https://test.browseraudit.com", "none", "https://browseraudit.com", "none")	t
44	parent: document.domain = "browseraudit.com", child: document.domain = "test.browseraudit.com"	\N	block	warning	5	4	parentChildSopTest(44, true, false, "https://test.browseraudit.com", "browseraudit.com", "https://browseraudit.com", "test.browseraudit.com")	t
45	parent: document.domain = "test.browseraudit.com", child: document.domain = "test.browseraudit.com"	\N	block	warning	5	5	parentChildSopTest(45, true, false, "https://test.browseraudit.com", "test.browseraudit.com", "https://browseraudit.com", "test.browseraudit.com")	t
48	parent: document.domain = "audit.com", child: document.domain = "audit.com"	\N	block	warning	5	8	parentChildSopTest(48, true, false, "https://test.browseraudit.com", "audit.com", "https://browseraudit.com", "audit.com")	t
50	parent: document.domain not set, child: document.domain = "browseraudit.com"	\N	block	warning	6	2	parentChildSopTest(50, true, true, "https://test.browseraudit.com", "none", "https://browseraudit.com", "browseraudit.com")	t
171	iframe from same origin with DENY	\N	block	warning	31	1	frameOptionsTest(171, true, "https://browseraudit.com", "DENY", true)	t
66	https://test.browseraudit.org to https://browseraudit.com (host mismatch)	\N	block	critical	7	10	ajaxSopTest(66, true, "https://test.browseraudit.org", "https://browseraudit.com")	t
68	https://browseraudit.org to https://test.browseraudit.com (host mismatch)	\N	block	critical	7	12	ajaxSopTest(68, true, "https://browseraudit.org", "https://test.browseraudit.com")	t
85	cookie for .browseraudit.com set by browseraudit.com is sent to browseraudit.com	\N	allow	critical	8	1	domainScopeCookieTest(85, false, "browseraudit.com", ".browseraudit.com", "browseraudit.com")	t
87	cookie for .browseraudit.com set by test.browseraudit.com is sent to browseraudit.com	\N	allow	critical	8	3	domainScopeCookieTest(87, false, "test.browseraudit.com", ".browseraudit.com", "browseraudit.com")	t
90	cookie for .test.browseraudit.com is not sent to browseraudit.com	\N	block	critical	8	6	domainScopeCookieTest(90, true, "test.browseraudit.com", ".test.browseraudit.com", "browseraudit.com")	t
94	cookie for .browseraudit.org set by test.browseraudit.org is not sent to test.browseraudit.com	\N	block	critical	8	10	domainScopeCookieTest(94, true, "test.browseraudit.org", ".browseraudit.org", "test.browseraudit.com")	t
96	cookie for .test.browseraudit.org set by test.browseraudit.org is not sent to test.browseraudit.com	\N	block	critical	8	12	domainScopeCookieTest(96, true, "test.browseraudit.org", ".test.browseraudit.org", "test.browseraudit.com")	t
97	cookie for .test.browseraudit.com set by browseraudit.com is not sent to test.browseraudit.com (illegal parameter)	\N	block	critical	9	1	domainScopeCookieTest(97, true, "browseraudit.com", ".test.browseraudit.com", "test.browseraudit.com")	t
101	cookie for .com set by test.browseraudit.com is not sent to browseraudit.com (illegal parameter)	\N	block	critical	9	5	domainScopeCookieTest(101, true, "test.browseraudit.com", ".com", "browseraudit.com")	t
190	stylesheet @import from https://browseraudit.com with default-src 'none'	\N	block	warning	12	6	cspTest(190, 31, "default-src 'unsafe-inline'", true, {})	t
192	stylesheet @import from https://browseraudit.com with style-src 'none'	\N	block	warning	12	8	cspTest(192, 33, "default-src 'none'; style-src 'unsafe-inline'", true, {})	t
195	stylesheet from https://test.browseraudit.com with default-src https://test.browseraudit.com	\N	allow	warning	12	11	cspTest(195, 22, "default-src https://test.browseraudit.com", false, {})	t
199	stylesheet from https://test.browseraudit.com with style-src 'none'	\N	block	warning	12	15	cspTest(199, 25, "default-src https://test.browseraudit.com; style-src 'none'", true, {})	t
206	stylesheet @import from https://test.browseraudit.com with style-src 'self'	\N	block	warning	12	22	cspTest(206, 69, "default-src none'; style-src 'self' 'unsafe-inline'", true, {})	t
211	script from https://test.browseraudit.com with default-src https://test.browseraudit.com	\N	allow	warning	13	5	cspTest(211, 42, "default-src https://test.browseraudit.com", false, {})	t
213	script from https://test.browseraudit.com with default-src 'self'	\N	block	warning	13	7	cspTest(213, 70, "default-src 'none'", true, {})	t
219	Worker from https://browseraudit.com with script-src 'self'	300	allow	warning	13	13	cspTest(219, 48, "default-src 'none'; script-src 'unsafe-inline' 'self'", false, { timeout: 300 })	t
220	Worker from https://browseraudit.com with script-src 'none'	300	block	warning	13	14	cspTest(220, 49, "default-src 'self'; script-src 'unsafe-inline'", true, { timeout: 300 })	t
223	SharedWorker from https://browseraudit.com with script-src 'self'	300	allow	warning	13	17	cspTest(223, 52, "default-src 'none'; script-src 'unsafe-inline' 'self'", false, { timeout: 300 })	t
74	https://test.browseraudit.com to http://browseraudit.com (scheme and host mismatch)	\N	block	critical	7	19	ajaxSopTest(74, true, "https://test.browseraudit.com", "http://browseraudit.com")	t
224	SharedWorker from https://browseraudit.com with script-src 'none'	300	block	warning	13	18	cspTest(224, 53, "default-src 'self'; script-src 'unsafe-inline'", true, { timeout: 300 })	t
228	inline event handler with default-src 'none'	300	block	warning	14	4	cspTest(228, 6, "default-src 'none'", true, { timeout: 300 })	t
229	inline <style> with default-src 'unsafe-inline'	\N	allow	warning	14	5	cspTest(229, 7, "default-src 'self' 'unsafe-inline'", false, {})	t
233	Function constructor with default-src 'unsafe-eval'	\N	allow	warning	15	1	cspTest(233, 11, "default-src 'unsafe-inline' 'unsafe-eval'", false, {})	t
234	Function constructor without 'unsafe-eval'	\N	block	warning	15	2	cspTest(234, 12, "default-src 'unsafe-inline'", true, {})	t
239	setInterval() with default-src 'unsafe-eval'	1000	allow	warning	15	7	cspTest(239, 17, "default-src 'unsafe-inline' 'unsafe-eval'", false, { timeout: 1000 })	t
240	setInterval() without 'unsafe-eval'	1000	block	warning	15	8	cspTest(240, 18, "default-src 'unsafe-inline'", true, { timeout: 1000 })	t
263	image from https://browseraudit.com with img-src 'self'	\N	allow	warning	17	3	cspTest(263, 80, "default-src 'none'; img-src 'self'", false, {})	t
268	image from https://test.browseraudit.com with img-src https://test.browseraudit.com	\N	allow	warning	17	8	cspTest(268, 85, "default-src 'none'; img-src https://test.browseraudit.com", false, {})	t
244	object from https://browseraudit.com with object-src 'none'	300	block	warning	16	4	cspTest(244, 55, "default-src 'self'; object-src 'none'", true, { timeout: 300 })	f
245	object from https://test.browseraudit.com with default-src https://test.browseraudit.com	300	allow	warning	16	5	cspTest(245, 60, "default-src https://test.browseraudit.com", false, { timeout: 300 })	f
249	object from https://test.browseraudit.com with object-src 'none'	300	block	warning	16	9	cspTest(249, 63, "default-src https://test.browseraudit.com; object-src 'none'", true, { timeout: 300 })	f
252	embed from https://browseraudit.com with default-src 'none'	300	block	warning	16	12	cspTest(252, 57, "default-src 'none'", true, { timeout: 300 })	f
255	embed from https://test.browseraudit.com with default-src https://test.browseraudit.com	300	allow	warning	16	15	cspTest(255, 72, "default-src https://test.browseraudit.com", false, { timeout: 300 })	f
256	embed from https://test.browseraudit.com with default-src 'none'	300	block	warning	16	16	cspTest(256, 73, "default-src 'none'", true, { timeout: 300 })	f
260	embed from https://test.browseraudit.com with object-src 'self'	300	block	warning	16	20	cspTest(260, 77, "default-src 'none'; object-src 'self'", true, { timeout: 300 })	f
269	image from https://test.browseraudit.com with img-src 'none'	\N	block	warning	17	9	cspTest(269, 86, "default-src https://test.browseraudit.com; img-src 'none'", true, {})	t
274	audio from https://browseraudit.com with media-src 'none'	\N	block	warning	18	4	cspTest(274, 91, "default-src 'self'; media-src 'none'", true, {})	t
278	audio from https://test.browseraudit.com with media-src https://test.browseraudit.com	\N	allow	warning	18	8	cspTest(278, 95, "default-src 'none'; media-src https://test.browseraudit.com", false, {})	t
279	audio from https://test.browseraudit.com with media-src 'none'	\N	block	warning	18	9	cspTest(279, 96, "default-src https://test.browseraudit.com; media-src 'none'", true, {})	t
284	video from https://browseraudit.com with media-src 'none'	\N	block	warning	18	14	cspTest(284, 101, "default-src 'self'; media-src 'none'", true, {})	t
288	video from https://test.browseraudit.com with media-src https://test.browseraudit.com	\N	allow	warning	18	18	cspTest(288, 105, "default-src 'none'; media-src https://test.browseraudit.com", false, {})	t
289	video from https://test.browseraudit.com with media-src 'none'	\N	block	warning	18	19	cspTest(289, 106, "default-src https://test.browseraudit.com; media-src 'none'", true, {})	t
295	iframe from https://test.browseraudit.com with default-src https://test.browseraudit.com	\N	allow	warning	19	5	cspTest(295, 112, "default-src https://test.browseraudit.com", false, {})	t
299	iframe from https://test.browseraudit.com with frame-src 'none'	\N	block	warning	19	9	cspTest(299, 116, "default-src https://test.browseraudit.com; frame-src 'none'", true, {})	t
303	frame from https://browseraudit.com with frame-src 'self'	\N	allow	warning	19	13	cspTest(303, 120, "default-src 'none'; frame-src 'self'", false, {})	t
308	frame from https://test.browseraudit.com with frame-src https://test.browseraudit.com	\N	allow	warning	19	18	cspTest(308, 125, "default-src 'none'; frame-src https://test.browseraudit.com", false, {})	t
312	@font-face from https://browseraudit.com in inline stylesheet with default-src 'none'	300	block	warning	33	2	cspTest(312, 129, "default-src 'none'; style-src 'unsafe-inline'", true, { timeout: 300 })	t
315	@font-face from https://browseraudit.com in @import in inline stylesheet with default-src 'self'	300	allow	warning	33	5	cspTest(315, 132, "default-src 'self'; style-src 'self' 'unsafe-inline'", false, { timeout: 300 })	t
318	@font-face from https://browseraudit.com in @import in inline stylesheet with font-src 'none'	300	block	warning	33	8	cspTest(318, 135, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'none'", true, { timeout: 300 })	t
324	@font-face from https://browseraudit.com in @import in stylesheet included via <link> with default-src 'none'	300	block	warning	33	14	cspTest(324, 141, "default-src 'none'; style-src 'self' 'unsafe-inline'", true, { timeout: 300 })	t
325	@font-face from https://browseraudit.com in @import in stylesheet included via <link> with font-src 'self'	300	allow	warning	33	15	cspTest(325, 142, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'self'", false, { timeout: 300 })	t
330	@font-face from https://test.browseraudit.com in inline stylesheet with font-src https://test.browseraudit.com	300	allow	warning	33	20	cspTest(330, 147, "default-src 'none'; style-src 'unsafe-inline'; font-src https://test.browseraudit.com", false, { timeout: 300 })	t
335	@font-face from https://test.browseraudit.com in @import in inline stylesheet with default-src 'self'	300	block	warning	33	25	cspTest(335, 152, "default-src 'self'; style-src 'self' 'unsafe-inline'", true, { timeout: 300 })	t
336	@font-face from https://test.browseraudit.com in @import in inline stylesheet with font-src https://test.browseraudit.com	300	allow	warning	33	26	cspTest(336, 153, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src https://test.browseraudit.com", false, { timeout: 300 })	t
340	@font-face from https://test.browseraudit.com in stylesheet included via <link> with default-src 'none'	300	block	warning	33	30	cspTest(340, 157, "default-src 'none'; style-src 'self'  'unsafe-inline'", true, { timeout: 300 })	t
343	@font-face from https://test.browseraudit.com in stylesheet included via <link> with font-src 'none'	300	block	warning	33	33	cspTest(343, 160, "default-src https://test.browseraudit.com; style-src 'self' 'unsafe-inline'; font-src 'none'", true, { timeout: 300 })	t
346	@font-face from https://test.browseraudit.com in @import in stylesheet included via <link> with default-src 'none'	300	block	warning	33	36	cspTest(346, 163, "default-src 'none'; style-src 'self'  'unsafe-inline'", true, { timeout: 300 })	t
348	@font-face from https://test.browseraudit.com in @import in stylesheet included via <link> with font-src https://test.browseraudit.com	300	allow	warning	33	38	cspTest(348, 165, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src https://test.browseraudit.com", false, { timeout: 300 })	t
350	@font-face from https://test.browseraudit.com in @import in stylesheet included via <link> with font-src 'self'	300	block	warning	33	40	cspTest(350, 167, "default-src 'none'; style-src 'self' 'unsafe-inline'; font-src 'self'", true, { timeout: 300 })	t
354	XMLHttpRequest.open() to https://browseraudit.com with connect-src 'none'	\N	block	warning	35	4	cspTest(354, 171, "default-src 'self'; script-src 'unsafe-inline'; connect-src 'none'", true, {})	t
355	XMLHttpRequest.open() to https://test.browseraudit.com with default-src https://test.browseraudit.com	\N	allow	warning	35	5	cspTest(355, 172, "default-src https://test.browseraudit.com; script-src 'unsafe-inline'", false, {})	t
358	XMLHttpRequest.open() to https://test.browseraudit.com with connect-src https://test.browseraudit.com	\N	allow	warning	35	8	cspTest(358, 175, "default-src 'none'; script-src 'unsafe-inline'; connect-src https://test.browseraudit.com", false, {})	t
359	XMLHttpRequest.open() to https://test.browseraudit.com with connect-src 'none'	\N	block	warning	35	9	cspTest(359, 176, "connect-src 'self'; script-src 'unsafe-inline'; connect-src 'none'", true, {})	t
362	WebSocket connecting to wss://browseraudit.com with default-src 'none'	300	block	warning	35	12	cspTest(362, 179, "default-src 'none'; script-src 'unsafe-inline'", true, { timeout: 300 })	t
363	WebSocket connecting to wss://browseraudit.com with default-src wss://browseraudit.com	300	allow	warning	35	13	cspTest(363, 180, "default-src wss://browseraudit.com; script-src 'unsafe-inline'", false, { timeout: 300 })	t
365	WebSocket connecting to wss://browseraudit.com with connect-src 'none'	300	block	warning	35	15	cspTest(365, 182, "default-src 'self'; script-src 'unsafe-inline'; connect-src 'none'", true, { timeout: 300 })	t
370	WebSocket connecting to wss://test.browseraudit.com with connect-src 'self'	300	block	warning	35	20	cspTest(370, 187, "default-src 'none'; script-src 'unsafe-inline'; connect-src 'self'", true, { timeout: 300 })	t
374	EventSource connecting to https://browseraudit.com with default-src 'none'	300	block	warning	35	24	cspTest(374, 191, "default-src 'none'; script-src 'unsafe-inline'", true, { timeout: 300 })	t
377	EventSource connecting to https://test.browseraudit.com with default-src https://test.browseraudit.com	300	allow	warning	35	27	cspTest(377, 194, "default-src https://test.browseraudit.com; script-src 'unsafe-inline'", false, { timeout: 300 })	t
380	EventSource connecting to https://test.browseraudit.com with connect-src https://test.browseraudit.com	300	allow	warning	35	30	cspTest(380, 197, "default-src 'none'; script-src 'unsafe-inline'; connect-src https://test.browseraudit.com", false, { timeout: 300 })	t
382	EventSource connecting to https://test.browseraudit.com with connect-src 'self'	300	block	warning	35	32	cspTest(382, 199, "default-src 'none'; script-src 'unsafe-inline'; connect-src 'self'", true, { timeout: 300 })	t
384	DOM access from child iframe on https://browseraudit.com to parent iframe on https://browseraudit.com without sandbox allow-same-origin	\N	block	warning	36	2	cspTest(384, 201, "sandbox allow-scripts", true, {})	t
386	DOM access from child iframe on https://test.browseraudit.com to parent iframe on https://browseraudit.com without sandbox allow-same-origin	\N	block	warning	36	4	cspTest(386, 203, "sandbox allow-scripts", true, {})	t
393	Access from child iframe on https://test.browseraudit.com to cookie on .browseraudit.com with sandbox allow-same-origin	\N	allow	warning	36	11	cspTest(393, 210, "sandbox allow-same-origin allow-scripts", false, {})	t
394	Access from child iframe on https://test.browseraudit.com to cookie on .browseraudit.com without sandbox allow-same-origin	\N	block	warning	36	12	cspTest(394, 211, "sandbox allow-scripts", true, {})	t
397	Script execution via onload event with sandbox allow-scripts	300	allow	warning	36	15	cspTest(397, 222, "sandbox allow-scripts", false, { timeout: 300 })	t
401	Submission of form via POST with sandbox allow-forms	300	allow	warning	36	19	cspTest(401, 226, "sandbox allow-scripts allow-forms", false, { timeout: 300 })	t
115	Method DELETE with Access-Control-Allow-Methods: TRACE, DELETE	\N	allow	warning	22	7	methodExpect(115, "DELETE", "TRACE, DELETE")	t
122	Method OPTIONS with Access-Control-Allow-Methods: CONNECT, PATCH	\N	block	warning	22	14	methodExpect(122, "OPTIONS", "CONNECT, PATCH", true)	t
125	Request with custom header X-My-Header with Access-Control-Allow-Headers: X-My-Header	\N	allow	warning	23	2	headersExpect(125, {"X-My-Header": "foo"}, "X-My-Header", false)	t
126	Request with custom header X-My-Header with Access-Control-Allow-Headers: X-Another-Header	\N	block	warning	23	3	headersExpect(126, {"X-My-Header": "foo"}, "X-Another-Header", true)	t
129	Request with custom headers X-My-Header and X-Another-Header with no Access-Control-Allow-Headers header present	\N	block	warning	23	6	headersExpect(129, {"X-My-Header": "foo", "X-Another-Header": "bar"}, "none", true)	t
131	Request with custom headers X-My-Header and X-Another-Header with Access-Control-Allow-Headers: X-Another-Header	\N	block	warning	23	8	headersExpect(131, {"X-My-Header": "foo", "X-Another-Header": "bar"}, "X-Another-Header", true)	t
132	Request with custom headers X-My-Header and X-Another-Header with Access-Control-Allow-Headers: X-Yet-Another-Header	\N	block	warning	23	9	headersExpect(132, {"X-My-Header": "foo", "X-Another-Header": "bar"}, "X-Yet-Another-Header", true)	t
136	Request with custom headers X-My-Header and X-Another-Header with Access-Control-Allow-Headers: X-My-Header, X-Another-Header	\N	allow	warning	23	13	headersExpect(136, {"X-My-Header": "foo", "X-Another-Header": "bar"}, "X-My-Header, X-Another-Header", false)	t
139	Caller can access Content-Language with no Access-Control-Expose-Headers header	\N	allow	warning	24	2	exposeExpect(139, "Content-Language", "none", false)	t
144	Caller can't access Server with no Access-Control-Expose-Headers header	\N	block	warning	24	7	exposeExpect(144, "Server", "none", true)	t
148	Caller can't access Server with Access-Control-Expose-Headers: Content-Length, Connection	\N	block	warning	24	11	exposeExpect(148, "Server", "Content-Length, Connection", true)	t
151	Caller can access Content-Length with Access-Control-Expose-Headers: Connection, Content-Length	\N	allow	warning	24	14	exposeExpect(151, "Content-Length", "Connection, Content-Length", false)	t
153	Caller can't access Content-Length with Access-Control-Expose-Headers: Date, Connection	\N	block	warning	24	16	exposeExpect(153, "Content-Length", "Date, Connection", true)	t
156	Caller can access Connection with Access-Control-Expose-Headers: Date, Connection	\N	allow	warning	24	19	exposeExpect(156, "Connection", "Date, Connection", false)	t
180	HSTS policy should not apply to subdomains when includeSubDomains is omitted	\N	allow	warning	32	2	hstsTest(180, "max-age=2", "https://browseraudit.com", "http://test.browseraudit.com", "http", {})	t
181	HSTS policy should apply to subdomains when includeSubDomains is included	\N	block	warning	32	3	hstsTest(181, "max-age=5; includeSubDomains", "https://browseraudit.com", "http://test.browseraudit.com", "https", {})	t
183	should expire after max-age	3000	block	warning	32	5	hstsTest(183, "max-age=2", "https://browseraudit.com", "http://browseraudit.com", "http", { setProtocolDelay: 3000, hstsPeriod: 2000 })	t
407	stylesheet from https://browseraudit.com with default-src 'self'	\N	allow	warning	37	1	cspTest(407, 214, "sandbox allow-same-origin allow-scripts", false, {})	f
75	https://browseraudit.com to http://browseraudit.org (scheme and host mismatch)	\N	block	critical	7	20	ajaxSopTest(75, true, "https://browseraudit.com", "http://browseraudit.org")	t
77	https://browseraudit.com to http://test.browseraudit.org (scheme and host mismatch)	\N	block	critical	7	22	ajaxSopTest(77, true, "https://browseraudit.com", "http://test.browseraudit.org")	t
84	https://test.browseraudit.org to http://test.browseraudit.org (scheme and host mismatch)	\N	block	critical	7	29	ajaxSopTest(84, true, "https://test.browseraudit.org", "http://test.browseraudit.org")	t
173	iframe from same origin with ALLOW-FROM browseraudit.com	\N	allow	warning	31	3	frameOptionsTest(173, false, "https://browseraudit.com", "ALLOW-FROM https://browseraudit.com", true)	f
174	iframe from same origin with ALLOW-FROM test.browseraudit.com	\N	block	warning	31	4	frameOptionsTest(174, true, "https://browseraudit.com", "ALLOW-FROM https://test.browseraudit.com", true)	f
178	iframe from remote origin with ALLOW-FROM browseraudit.com	\N	allow	warning	31	8	frameOptionsTest(178, false, "https://test.browseraudit.com", "ALLOW-FROM https://browseraudit.com/", true)	f
73	https://browseraudit.com to http://test.browseraudit.com (scheme and host mismatch)	\N	block	critical	7	18	ajaxSopTest(73, true, "https://browseraudit.com", "http://test.browseraudit.com")	t
76	https://browseraudit.org to http://browseraudit.com (scheme and host mismatch)	\N	block	critical	7	21	ajaxSopTest(76, true, "https://browseraudit.org", "http://browseraudit.com")	t
78	https://test.browseraudit.org to http://browseraudit.com (scheme and host mismatch)	\N	block	critical	7	23	ajaxSopTest(78, true, "https://test.browseraudit.org", "http://browseraudit.com")	t
80	https://browseraudit.org to http://test.browseraudit.com (scheme and host mismatch)	\N	block	critical	7	25	ajaxSopTest(80, true, "https://browseraudit.org", "http://test.browseraudit.com")	t
82	https://test.browseraudit.org to http://test.browseraudit.com (scheme and host mismatch)	\N	block	critical	7	27	ajaxSopTest(82, true, "https://test.browseraudit.org", "http://test.browseraudit.com")	t
81	https://test.browseraudit.com to http://test.browseraudit.org (scheme and host mismatch)	\N	block	critical	7	26	ajaxSopTest(81, true, "https://test.browseraudit.com", "http://test.browseraudit.org")	t
83	https://browseraudit.org to http://test.browseraudit.org (scheme and host mismatch)	\N	block	critical	7	28	ajaxSopTest(83, true, "https://browseraudit.org", "http://test.browseraudit.org")	t
79	https://test.browseraudit.com to http://browseraudit.org (scheme and host mismatch)	\N	block	critical	7	24	ajaxSopTest(79, true, "https://test.browseraudit.com", "http://browseraudit.org")	t
411	https://test.browseraudit.org to https://browseraudit.org (host mismatch)	\N	block	critical	7	17	ajaxSopTest(411, true, "https://test.browseraudit.org", "https://browseraudit.org")	t
366	WebSocket connecting to wss://browseraudit.com with connect-src wss://browseraudit.com	300	allow	warning	35	16	cspTest(366, 183, "default-src 'none'; script-src 'unsafe-inline'; connect-src wss://browseraudit.com", false, { timeout: 300 })	t
372	WebSocket connecting to wss://test.browseraudit.com with connect-src wss://test.browseraudit.com	300	allow	warning	35	22	cspTest(372, 189, "default-src 'none'; script-src 'unsafe-inline'; connect-src wss://test.browseraudit.com", false, { timeout: 300 })	t
30	parent: document.domain = "browseraudit.com", child: document.domain = "browseraudit.com"	\N	allow	warning	3	6	parentChildSopTest(30, false, false, "https://browseraudit.com", "browseraudit.com", "https://test.browseraudit.com", "browseraudit.com")	f
35	parent: document.domain = "browseraudit.com", child: document.domain not set	\N	block	warning	4	3	parentChildSopTest(35, true, true, "https://browseraudit.com", "browseraudit.com", "https://test.browseraudit.com", "none")	t
36	parent: document.domain = "browseraudit.com", child: document.domain = "test.browseraudit.com"	\N	block	warning	4	4	parentChildSopTest(36, true, true, "https://browseraudit.com", "browseraudit.com", "https://test.browseraudit.com", "test.browseraudit.com")	t
38	parent: document.domain = "browseraudit.com", child: document.domain = "browseraudit.com"	\N	allow	warning	4	6	parentChildSopTest(38, false, true, "https://browseraudit.com", "browseraudit.com", "https://test.browseraudit.com", "browseraudit.com")	f
49	parent: document.domain not set, child: document.domain not set	\N	block	warning	6	1	parentChildSopTest(49, true, true, "https://test.browseraudit.com", "none", "https://browseraudit.com", "none")	t
51	parent: document.domain = "browseraudit.com", child: document.domain not set	\N	block	warning	6	3	parentChildSopTest(51, true, true, "https://test.browseraudit.com", "browseraudit.com", "https://browseraudit.com", "none")	t
53	parent: document.domain = "test.browseraudit.com", child: document.domain = "test.browseraudit.com"	\N	block	warning	6	5	parentChildSopTest(53, true, true, "https://test.browseraudit.com", "test.browseraudit.com", "https://browseraudit.com", "test.browseraudit.com")	t
55	parent: document.domain = "test.browseraudit.com", child: document.domain = "browseraudit.com"	\N	allow	warning	6	7	parentChildSopTest(55, true, true, "https://test.browseraudit.com", "test.browseraudit.com", "https://browseraudit.com", "browseraudit.com")	f
175	iframe from remote origin with DENY	\N	block	warning	31	5	frameOptionsTest(175, true, "https://test.browseraudit.com", "DENY", true)	t
176	iframe from remote origin with SAMEORIGIN	\N	block	warning	31	6	frameOptionsTest(176, true, "https://test.browseraudit.com", "SAMEORIGIN", true)	t
243	object from https://browseraudit.com with object-src 'self'	300	allow	warning	16	3	cspTest(243, 54, "default-src 'none'; object-src 'self'", false, { timeout: 300 })	f
254	embed from https://browseraudit.com with object-src 'none'	300	block	warning	16	14	cspTest(254, 59, "default-src 'self'; object-src 'none'", true, { timeout: 300 })	f
258	embed from https://test.browseraudit.com with object-src https://test.browseraudit.com	300	allow	warning	16	18	cspTest(258, 75, "default-src 'none'; object-src https://test.browseraudit.com", false, { timeout: 300 })	f
259	embed from https://test.browseraudit.com with object-src 'none'	300	block	warning	16	19	cspTest(259, 76, "default-src https://test.browseraudit.com; object-src 'none'", true, { timeout: 300 })	f
412	frame from same origin with DENY	\N	block	warning	31	9	frameOptionsTest(171, true, "https://browseraudit.com", "DENY", false)	t
413	frame from same origin with SAMEORIGIN	\N	allow	warning	31	10	frameOptionsTest(172, false, "https://browseraudit.com", "SAMEORIGIN", false)	t
414	frame from same origin with ALLOW-FROM browseraudit.com	\N	allow	warning	31	11	frameOptionsTest(173, false, "https://browseraudit.com", "ALLOW-FROM https://browseraudit.com", false)	f
415	frame from same origin with ALLOW-FROM test.browseraudit.com	\N	block	warning	31	12	frameOptionsTest(174, true, "https://browseraudit.com", "ALLOW-FROM https://test.browseraudit.com", false)	f
416	frame from remote origin with DENY	\N	block	warning	31	13	frameOptionsTest(175, true, "https://test.browseraudit.com", "DENY", false)	t
417	frame from remote origin with SAMEORIGIN	\N	block	warning	31	14	frameOptionsTest(176, true, "https://test.browseraudit.com", "SAMEORIGIN", false)	t
418	frame from remote origin with ALLOW-FROM test.browseraudit.com	\N	block	warning	31	15	frameOptionsTest(177, true, "https://test.browseraudit.com", "ALLOW-FROM https://test.browseraudit.com", false)	f
419	frame from remote origin with ALLOW-FROM browseraudit.com	\N	allow	warning	31	16	frameOptionsTest(178, false, "https://test.browseraudit.com", "ALLOW-FROM https://browseraudit.com/", false)	f
420	iframe from https://browseraudit.com with child-src 'self'	\N	allow	warning	19	21	cspTest(420, 232, "default-src 'none'; child-src 'self'", false, {})	t
421	iframe from https://browseraudit.com with child-src 'none'	\N	block	warning	19	22	cspTest(421, 233, "default-src 'self'; child-src 'none'", true, {})	t
422	iframe from https://test.browseraudit.com with child-src https://test.browseraudit.com	\N	allow	warning	19	23	cspTest(422, 234, "default-src 'none'; child-src https://test.browseraudit.com", false, {})	t
423	iframe from https://test.browseraudit.com with child-src 'none'	\N	block	warning	19	24	cspTest(423, 235, "default-src https://test.browseraudit.com; child-src 'none'", true, {})	t
424	iframe from https://test.browseraudit.com with child-src 'self'	\N	block	warning	19	25	cspTest(424, 236, "default-src 'none'; child-src 'self'", true, {})	t
425	frame from https://browseraudit.com with child-src 'self'	\N	allow	warning	19	26	cspTest(425, 237, "default-src 'none'; child-src 'self'", false, {})	t
426	frame from https://browseraudit.com with child-src 'none'	\N	block	warning	19	27	cspTest(426, 238, "default-src 'self'; child-src 'none'", true, {})	t
427	frame from https://test.browseraudit.com with child-src https://test.browseraudit.com	\N	allow	warning	19	28	cspTest(427, 239, "default-src 'none'; child-src https://test.browseraudit.com", false, {})	t
428	frame from https://test.browseraudit.com with child-src 'none'	\N	block	warning	19	29	cspTest(428, 240, "default-src https://test.browseraudit.com; child-src 'none'", true, {})	t
429	frame from https://test.browseraudit.com with child-src 'self'	\N	block	warning	19	30	cspTest(429, 241, "default-src 'none'; child-src 'self'", true, {})	t
430	Worker from https://browseraudit.com with worker-src 'self'	300	allow	warning	38	1	cspTest(430, 242, "default-src 'none'; worker-src 'self'", false, { timeout: 300 })	t
431	Worker from https://browseraudit.com with worker-src 'none'	300	block	warning	38	2	cspTest(431, 243, "default-src 'self'; worker-src 'none'", true, { timeout: 300 })	t
432	Worker from https://test.browseraudit.com with worker-src https://test.browseraudit.com	300	allow	warning	38	3	cspTest(432, 244, "default-src 'none'; worker-src https://test.browseraudit.com", false, { timeout: 300 })	t
433	Worker from https://test.browseraudit.com with worker-src 'none'	300	block	warning	38	4	cspTest(433, 245, "default-src https://test.browseraudit.com; worker-src 'none'", true, { timeout: 300 })	t
434	Worker from https://test.browseraudit.com with worker-src 'self'	300	block	warning	38	5	cspTest(434, 246, "default-src 'none'; worker-src 'self'", true, { timeout: 300 })	t
435	SharedWorker from https://browseraudit.com with worker-src 'self'	300	allow	warning	38	6	cspTest(435, 247, "default-src 'none'; worker-src 'self'", false, { timeout: 300 })	t
436	SharedWorker from https://browseraudit.com with worker-src 'none'	300	block	warning	38	7	cspTest(436, 248, "default-src 'self'; worker-src 'none'", true, { timeout: 300 })	t
437	SharedWorker from https://test.browseraudit.com with worker-src https://test.browseraudit.com	300	allow	warning	38	8	cspTest(437, 249, "default-src 'none'; worker-src https://test.browseraudit.com", false, { timeout: 300 })	t
438	SharedWorker from https://test.browseraudit.com with worker-src 'none'	300	block	warning	38	9	cspTest(438, 250, "default-src https://test.browseraudit.com; worker-src 'none'", true, { timeout: 300 })	t
439	SharedWorker from https://test.browseraudit.com with worker-src 'self'	300	block	warning	38	10	cspTest(439, 251, "default-src 'none'; worker-src 'self'", true, { timeout: 300 })	t
440	Manifest from https://browseraudit.com with default-src 'self'	\N	allow	warning	39	1	cspTest(440, 252, "default-src 'self'", false, {})	t
441	Manifest from https://browseraudit.com with default-src 'none'	\N	block	warning	39	2	cspTest(441, 253, "default-src 'none'", true, {})	t
442	Manifest from https://browseraudit.com with manifest-src 'self'	\N	allow	warning	39	3	cspTest(442, 254, "default-src 'none'; manifest-src 'self'", false, {})	t
443	Manifest from https://browseraudit.com with manifest-src 'none'	\N	block	warning	39	4	cspTest(443, 255, "default-src 'self'; manifest-src 'none'", true, {})	t
444	Manifest from https://test.browseraudit.com with default-src https://test.browseraudit.com	\N	allow	warning	39	5	cspTest(444, 256, "default-src https://test.browseraudit.com", false, {})	t
445	Manifest from https://test.browseraudit.com with default-src 'none'	\N	block	warning	39	6	cspTest(445, 257, "default-src 'none'", true, {})	t
446	Manifest from https://test.browseraudit.com with default-src 'self'	\N	block	warning	39	7	cspTest(446, 258, "default-src 'none'", true, {})	t
448	Manifest from https://test.browseraudit.com with manifest-src 'none'	\N	block	warning	39	9	cspTest(448, 260, "default-src https://test.browseraudit.com; manifest-src 'none'", true, {})	t
449	Manifest from https://test.browseraudit.com with manifest-src 'self'	\N	block	warning	39	10	cspTest(449, 261, "default-src 'none'; manifest-src 'self'", true, {})	t
447	Manifest from https://test.browseraudit.com with manifest-src https://test.browseraudit.com	\N	allow	warning	39	8	cspTest(447, 259, "default-src 'none'; manifest-src https://test.browseraudit.com", false, {})	t
450	Referrer-Policy 'no-referrer' from https://browseraudit.com	\N	block	warning	40	1	requestReferrerPolicy(450, "", "no-referrer", "empty")	t
451	Referrer-Policy 'origin' from https://browseraudit.com	\N	allow	warning	40	2	requestReferrerPolicy(451, "", "origin", "origin")	t
452	Referrer-Policy 'no-referrer' from https://test.browseraudit.com	\N	block	warning	40	3	requestReferrerPolicy(452, "https://test.browseraudit.com", "no-referrer", "empty")	t
453	Referrer-Policy 'origin' from https://test.browseraudit.com	\N	allow	warning	40	4	requestReferrerPolicy(453, "https://test.browseraudit.com", "origin", "origin")	t
454	Referrer-Policy 'same-origin' from https://browseraudit.com	\N	allow	warning	40	5	requestReferrerPolicy(454, "", "same-origin", "full")	t
455	Referrer-Policy 'same-origin' with cross origin on https://test.browseraudit.com	\N	block	warning	40	6	requestReferrerPolicy(455, "https://test.browseraudit.com", "same-origin", "empty")	t
456	Referrer-Policy 'origin-when-cross-origin' from https://browseraudit.com	\N	allow	warning	40	7	requestReferrerPolicy(456, "", "origin-when-cross-origin", "full")	t
457	Referrer-Policy 'origin-when-cross-origin' from https://test.browseraudit.com	\N	block	warning	40	8	requestReferrerPolicy(457, "https://test.browseraudit.com", "origin-when-cross-origin", "origin")	t
458	Referrer-Policy 'unsafe-url'	\N	allow	warning	40	9	requestReferrerPolicy(458, "", "unsafe-url", "full")	t
459	Form with action from https://browseraudit.com and form-action 'self'	\N	allow	warning	41	1	cspTest(459, 262, "form-action 'self'", false, {})	t
460	Form from https://browseraudit.com and form-action 'none'	\N	block	warning	41	2	cspTest(460, 263, "form-action 'none'", true, {})	t
461	Form with action from https://test.browseraudit.com and form-action https://test.browseraudit.com	\N	allow	warning	41	3	cspTest(461, 264, "form-action https://test.browseraudit.com", false, {})	t
462	Form with action from https://test.browseraudit.com and form-action 'none'	\N	block	warning	41	4	cspTest(462, 265, "form-action 'none'", true, {})	t
463	Form with action from https://test.browseraudit.com and form-action 'self'	\N	block	warning	41	5	cspTest(463, 266, "form-action 'self'", true, {})	t
464	report received with report-to	300	block	warning	34	3	cspTest(464, 267,  "default-src 'none'; report-to endpoint-1", false, { timeout: 300 })	t
465	Framing with frame-ancestors 'none'	\N	block	warning	42	1	cspTest(465, 268, "frame-ancestors 'none'", true, {})	t
466	Framing https://browseraudit.com with frame-ancestors 'self'	\N	allow	warning	42	2	cspTest(466, 269, "frame-ancestors 'self'", false, {})	t
467	Framing https://browseraudit.com with frame-ancestors 'https://browseraudit.com'	\N	allow	warning	42	3	cspTest(467, 270, "frame-ancestors https://browseraudit.com", false, {})	t
468	Framing https://browseraudit.com with frame-ancestors scheme source 'https:'	\N	allow	warning	42	4	cspTest(468, 271, "frame-ancestors https:", false, {})	t
469	Framing https://browseraudit.com with frame-ancestors wildcard 'https://*.browseraudit.com'	\N	block	warning	42	5	cspTest(469, 272, "frame-ancestors https://*.browseraudit.com", true, {})	t
470	Framing https://browseraudit.com with frame-ancestors 'https://test.browseraudit.com'	\N	block	warning	42	6	cspTest(470, 273, "frame-ancestors https://test.browseraudit.com", true, {})	t
471	Access-Control-Allow-Credentials true with Allow-Origin "https://browseraudit.com"	\N	allow	warning	43	1	credentialsExpect(471, "https://browseraudit.com", "true", false)	t
472	Access-Control-Allow-Credentials true with Allow-Origin "https://test.browseraudit.com"	\N	block	warning	43	2	credentialsExpect(472, "https://test.browseraudit.com", "true", true)	t
473	Access-Control-Allow-Credentials true with Allow-Origin "*"	\N	block	warning	43	3	credentialsExpect(473, "*", "true", true)	t
474	Access-Control-Allow-Credentials omitted with Allow-Origin "https://browseraudit.com"	\N	block	warning	43	4	credentialsExpect(474, "https://browseraudit.com", "false", true)	t
\.


ALTER TABLE public.test ENABLE TRIGGER ALL;

--
-- Name: category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: browseraudit_user
--

SELECT pg_catalog.setval('public.category_id_seq', 44, false);


--
-- Name: test_id_seq; Type: SEQUENCE SET; Schema: public; Owner: browseraudit_user
--

SELECT pg_catalog.setval('public.test_id_seq', 475, false);


--
-- PostgreSQL database dump complete
--

