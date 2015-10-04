# BrowserAudit

[BrowserAudit](https://browseraudit.com) is a free web-based service for testing web browsers' implementations of various security policies. The BrowserAudit test suite currently contains over 400 tests exercising policies including the [same-origin policy](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy), the [Content Security Policy (1.0)](http://www.w3.org/TR/2012/CR-CSP-20121115/), and [HTTP Strict Transport Security](https://developer.mozilla.org/en-US/docs/Web/Security/HTTP_strict_transport_security).

BrowserAudit reports results in the browser as the tests are executed. Results are colour-coded using a simple "traffic light" system; advanced users may drill down to view the pass/fail status and the source code of individual tests by clicking on elements of the UI. Categories are also colour-coded according to whether they contain any failing tests.

This repository contains the full client-side and server-side source code, including configuration files, for the [BrowserAudit](https://browseraudit.com) web service. A database dump of the test suite can be found in [a separate repository](https://github.com/browseraudit/testsuite).

## Installation

> **Please note** that BrowserAudit is not a tool designed to be installed and run locally: it is to be hosted on a web server and is designed to be accessed from a web browser. The simplest way to use BrowserAudit is therefore to visit the public service we host at https://browseraudit.com.
> 
> Although this repository contains the full source code for BrowserAudit, note that it is not currently designed to be hosted on any domain other than `browseraudit.com`; local DNS records for `[test.]browseraudit.{com,org}` will therefore have to be set if you intend to run a local installation of BrowserAudit.

BrowserAudit is designed to be hosted on a server running the following software:

* [nginx](http://nginx.org), a HTTP(S) server
* [PostgreSQL](http://www.postgresql.org), a relational database server
* [Memcached](http://memcached.org), a memory caching system
* The [Go programming language](https://golang.org)
* [Supervisor](http://supervisord.org), a process control daemon

Configuration files for this software are available in the `etc/` directory. Files and configuration directives specific to [the live version of BrowserAudit](https://browseraudit.com), such as SSL certificates, are not included.

The BrowserAudit server itself depends upon the following non-standard Go libraries, all of which can be installed in the usual way (`$ go get [url]`):

* ```code.google.com/p/gcfg```
* ```github.com/bradfitz/gomemcache/memcache```
* ```github.com/gorilla/context```
* ```github.com/gorilla/mux```
* ```github.com/jmoiron/sqlx```
* ```github.com/lib/pq```
* ```github.com/oschwald/geoip2-golang```

After these dependencies are installed, the server can be compiled in the usual way for Go software:

* ```$ cd /path/to/browseraudit```
* ```$ go install```

The BrowserAudit server is configured using the `server.cfg` file. A commented sample file, named `server.cfg-dist`, can be found in the root of the repository.

BrowserAudit makes use of geolocation data published by [MaxMind](https://www.maxmind.com/en/home). Either of the [GeoIP2](https://www.maxmind.com/en/geoip2-databases) (commercial) or [GeoLite2](http://dev.maxmind.com/geoip/geoip2/geolite2/) (free) geolocation databases is required to run the server.

## License

BrowserAudit is free software, licensed under the terms of the 2-clause BSD license. See the `LICENSE` file for further details.

## Please cite BrowserAudit!

If you would like to cite BrowserAudit in your academic work, please cite our [ISSTA 2015](http://issta2015.cs.uoregon.edu/) [conference paper](http://www.doc.ic.ac.uk/~maffeis/papers/issta15.pdf):

> Charlie Hothersall-Thomas, Sergio Maffeis and Chris Novakovic. **BrowserAudit: Automated Testing of Browser Security Features**. In *Proceedings of the 2015 International Symposium on Software Testing and Analysis (ISSTA 2015)*, Baltimore, MD, USA, July 12-17, 2015. ACM 2015, ISBN 978-1-4503-3620-8.
