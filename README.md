# BrowserAudit

[BrowserAudit](https://browseraudit.com) is a free web-based service for testing web browsers' implementations of various security policies. The BrowserAudit test suite currently contains 431 tests exercising policies including the [same-origin policy](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy), the [Content Security Policy](https://www.w3.org/TR/CSP3/), and [HTTP Strict Transport Security](https://developer.mozilla.org/en-US/docs/Web/Security/HTTP_strict_transport_security).

BrowserAudit reports results in the browser as the tests are executed. Results are colour-coded using a simple "traffic light" system; advanced users may drill down to view the pass/fail status and the source code of individual tests by clicking on elements of the UI. Categories are also colour-coded according to whether they contain any failing tests.

> **Please note** that BrowserAudit is designed to be hosted on a web server, and accessed from a web browser. The simplest way to use BrowserAudit is to visit the public service we host at https://browseraudit.com.

This repository contains the full client-side and server-side source code, including a database dump of the test suite, for those who want to contribute improvements or bug fixes to the project, or want to run browser testing locally.

## Installation

### DNS

The code in this repository assumes to be hosted on `[test.]browseraudit.{com,org}`. To test locally, you need to resolve your domains correctly, for example adding the snippet below at the end of your `/etc/hosts` file:

```
127.0.0.1       www.browseraudit.com
127.0.0.1       browseraudit.com
127.0.0.1       test.browseraudit.com
127.0.0.1       browseraudit.org
127.0.0.1       test.browseraudit.org
```

### Certificates

You also need a local Certificate Authority and a TLS certificate for the domains above.

#### Generate CA key and certificate:

```
openssl genrsa -out browserauditCA.key 4096
openssl req -x509 -new -nodes -key browserauditCA.key -sha256 -days 1825 \
  -out browserauditCA.pem \
  -subj "/CN=browserauditCA"
```

#### Generate server key and CSR:

```
openssl genrsa -out privkey.pem 2048
openssl req -new -key privkey.pem -out request.csr \
  -subj "/CN=browseraudit.com" \
  -addext "subjectAltName=DNS:browseraudit.com,DNS:www.browseraudit.com,DNS:test.browseraudit.com,DNS:browseraudit.org,DNS:test.browseraudit.org"
```

#### Create a file named `v3.ext` with content:

```
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = browseraudit.com
DNS.2 = www.browseraudit.com
DNS.3 = test.browseraudit.com
DNS.4 = browseraudit.org
DNS.5 = test.browseraudit.org
```

#### Sign server certificate with CA key and verify:

```
openssl x509 -req -in request.csr -CA browserauditCA.pem -CAkey browserauditCA.key -CAcreateserial \
  -out fullchain.pem -days 365 -sha256 -extfile v3.ext
cat fullchain.pem browserauditCA.pem > fullchain.pem
openssl verify -CAfile browserauditCA.pem fullchain.pem
```

#### Copy `privkey.pem` and `fullchain.pem` in the `nginx/config` directory of this repo.

### Geolocation database

BrowserAudit makes use of geolocation data published by [MaxMind](https://www.maxmind.com/en/home). Get the (free) geolocation database file `GeoLite2-Country.mmdb` from [GeoLite2](http://dev.maxmind.com/geoip/geoip2/geolite2/) and place it in the directory `geoip` of this repo.

### Docker

BrowserAudit is designed to be hosted on a server running the following software:

- [nginx](http://nginx.org), a HTTP(S) server
- [PostgreSQL](http://www.postgresql.org), a relational database server
- [Memcached](http://memcached.org), a memory caching system
- The [Go programming language](https://golang.org)

Luckily, BrowserAudit is fully containserised with Docker, so the main dependency is just a recent version of Docker. If you want to change the defualt configuration please inspect `docker-compose.yml`, `app.Dockerfile` and `nginx/nginx.Dockerfile` and you will be able to track down the various configuration files.

> WARNING: the configuration file `development-server.yml` is intended for local development only, and for ease of use it contains **hard-coded, insecure passwords**. If you plan to deploy BrowserAudit publicly make sure to change these.

#### Build and run the containers

Go to the root directory of this repo, run `docker compose up` and cross your fingers 😁.

#### Useful Docker commands:

```
# install once, then start each time BrowserAudit
docker compose up
# check that everything is running (you should see 4 containers)
docker ps
# stop everything
docker compose down
# while running, interact with a container
docker exec -it <container_id_or_name> /bin/bash
# example: check the database
docker exec -it postgres /bin/bash
# once on the postgres container shell, inspect the database
psql -U browseraudit_user -d browseraudit_db
```

## Development

The recommended usage is to starts all the containers, then edit the `go`, `js`, `html` files in the repo, and the `go_app` container will watch for changes and build/deploy BrowserAudit automatically for you.
If you'd like to integrate your changes with the main Browseraudit project, see the `CONTRIBUTING.md` file for details.

### Useful functions

We use [Gofmt](https://pkg.go.dev/cmd/gofmt), [Staticcheck](https://staticcheck.io/), and [Prettier](https://prettier.io/) for formatting and linting. Configuration files for these are included in the repository.

To format Go code, you can use the command:

`gofmt -w .`

To format JS, HTML and CSS files, you can use the command:

`npx prettier --write .`

To check for linting issues with Go code, you can use the command:

`$(go env GOPATH)/bin/staticcheck`

## License and Attribution

### License

BrowserAudit is free software, licensed under the terms of the 2-clause BSD license. See the `LICENSE` file for further details.

### Acknowledgments

This project has benefited from the contributions of several individuals over the years. We thank, in alphabetical order, Charlie Hothersall-Thomas, Luqman Liaquat, Sergio Maffeis, and Chris Novakovic for their efforts.

The initial research on BrowserAudit was partially supported by _EPSRC grant EP/I004246/1_ and _EPSRC grant EP/K032089/1_.
The initial deployment of BrowserAudit was partially supported by a _GCHQ Academic Cyber Funding Small Grant_.
Since 2015 [BrowserStack](https://www.browserstack.com/) has generously provided support in kind, by providing us with a free plan to access their browser testing automation framework.
Since December 2024 we acknowledge and thank [NLnet](https://nlnet.nl/) and the European Commission's [Next Generation Internet](https://ngi.eu/) programme [NGI0 Core](https://nlnet.nl/core) for their support which we hope will help us foster contributions from the developers community.

### Please Cite BrowserAudit!

If you would like to cite BrowserAudit in your academic work, please cite our [ISSTA 2015](http://issta2015.cs.uoregon.edu/) [conference paper](http://www.doc.ic.ac.uk/~maffeis/papers/issta15.pdf):

> Charlie Hothersall-Thomas, Sergio Maffeis and Chris Novakovic. **BrowserAudit: Automated Testing of Browser Security Features**. In _Proceedings of the 2015 International Symposium on Software Testing and Analysis (ISSTA 2015)_, Baltimore, MD, USA, July 12-17, 2015. ACM 2015, ISBN 978-1-4503-3620-8.
