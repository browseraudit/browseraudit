ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;

ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
ssl_prefer_server_ciphers on;

ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /srv/ssl/chain.crt;

server {
	listen 80;
	listen [::]:80;

	server_name browseraudit.com;

	location / {
		proxy_pass http://127.0.0.1:8080;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}

	# So test page can't be loaded over plain HTTP by mistake
	location = / {
		rewrite  .*  https://browseraudit.com/ permanent;
	}
	location /test {
		return 301 https://$host$request_uri;
	}

	location = /robots.txt {
		alias /home/go/go/src/github.com/browseraudit/browseraudit/robots.txt;
	}

	location ~ ^/([sg]et_(request|session)_secure_cookie|set_protocol) {
		proxy_pass http://127.0.0.1:8080;
		proxy_set_header X-Real-Ip $remote_addr;
		proxy_set_header X-Scheme $scheme;
		proxy_set_header X-Host $host;
		proxy_set_header X-Path /;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}

	location @homepage {
		rewrite  .*  https://browseraudit.com/ permanent;
	}
}

server {
	listen 443;
	listen [::]:443;

	server_name browseraudit.com;

	ssl on;
	ssl_certificate /srv/ssl/browseraudit.com.crt;
	ssl_certificate_key /srv/ssl/browseraudit.com.ecc.key;

	location / {
		proxy_pass http://127.0.0.1:8080;
		proxy_set_header X-Real-Ip $remote_addr;
		proxy_set_header X-Scheme $scheme;
		proxy_set_header X-Host $host;
		proxy_set_header X-Path /;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}

	location ~ ^/(category_tree|test_suite|clear_cookies|([sg]et_(request|session)_secure|csp|httponly)_cookie|get_destroy_me|[sg]et_referer|(set|clear)_hsts|[sg]et_protocol|csp|sop|frameoptions|cors|results|suite_execution|redirect) {
		proxy_pass http://127.0.0.1:8080;
		proxy_set_header X-Real-Ip $remote_addr;
		proxy_set_header X-Scheme $scheme;
		proxy_set_header X-Host $host;
		proxy_set_header X-Path /;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}
	location = /sop/path/clear_cookies {
		proxy_pass http://127.0.0.1:8080;
		proxy_set_header X-Real-Ip $remote_addr;
		proxy_set_header X-Scheme $scheme;
		proxy_set_header X-Host $host;
		proxy_set_header X-Path /sop/path/;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}

	location = /robots.txt {
		alias /home/go/go/src/github.com/browseraudit/browseraudit/robots.txt;
	}

	location /static/ {
		alias /home/go/go/src/github.com/browseraudit/browseraudit/static/;
	}

	location @homepage {
		rewrite  .*  https://browseraudit.com/ permanent;
	}
}

server {
	listen 80;
	listen [::]:80;

	server_name test.browseraudit.com;

	location / {
		rewrite  .*  https://browseraudit.com/ permanent;
	}

	location = /robots.txt {
		alias /home/go/go/src/github.com/browseraudit/browseraudit/robots.txt;
	}

	location ~ ^/(csp|sop|frameoptions|set_protocol) {
		proxy_pass http://127.0.0.1:8080;
		proxy_set_header X-Real-Ip $remote_addr;
		proxy_set_header X-Scheme $scheme;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}

	location @homepage {
		rewrite  .*  https://browseraudit.com/ permanent;
	}
}

server {
	listen 443;
	listen [::]:443;

	server_name test.browseraudit.com;

	ssl on;
	ssl_certificate /srv/ssl/browseraudit.com.crt;
	ssl_certificate_key /srv/ssl/browseraudit.com.ecc.key;

	location / {
		rewrite  .*  https://browseraudit.com/ permanent;
	}

	location = /clear_cookies {
		proxy_pass http://127.0.0.1:8080;
		proxy_set_header X-Real-Ip $remote_addr;
		proxy_set_header X-Host $host;
		proxy_set_header X-Path /;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}

	location = /csp_cookie {
		proxy_pass http://127.0.0.1:8080;
		proxy_set_header X-Real-Ip $remote_addr;
		proxy_set_header X-Host $host;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}

	location = /robots.txt {
		alias /home/go/go/src/github.com/browseraudit/browseraudit/robots.txt;
	}

	location ~ ^/(csp|sop|frameoptions|cors|set_protocol) {
		proxy_pass http://127.0.0.1:8080;
		proxy_set_header X-Real-Ip $remote_addr;
		proxy_set_header X-Scheme $scheme;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}

	location /static/ {
		alias /home/go/go/src/github.com/browseraudit/browseraudit/static/;
	}

	location @homepage {
		rewrite  .*  https://browseraudit.com/ permanent;
	}
}

server {
	listen 80;
	listen [::]:80;

	server_name browseraudit.org test.browseraudit.org www.browseraudit.com www.browseraudit.org;

	location / {
		rewrite  .*  https://browseraudit.com/ permanent;
	}
}

server {
	listen 443;
	listen [::]:443;

	server_name browseraudit.org test.browseraudit.org;

	ssl on;
	ssl_certificate /srv/ssl/browseraudit.org.crt;
	ssl_certificate_key /srv/ssl/browseraudit.org.ecc.key;

	location / {
		rewrite  .*  https://browseraudit.com/ permanent;
	}

	location = /clear_cookies {
		proxy_pass http://127.0.0.1:8080;
		proxy_set_header X-Real-Ip $remote_addr;
		proxy_set_header X-Host $host;
		proxy_set_header X-Path /;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}

	location ~ ^/sop {
		proxy_pass http://127.0.0.1:8080;
		proxy_set_header X-Real-Ip $remote_addr;
		proxy_intercept_errors on;
		error_page 404 = @homepage;
	}

	location /static/ {
		alias /home/go/go/src/github.com/browseraudit/browseraudit/static/;
	}

	location @homepage {
		rewrite  .*  https://browseraudit.com/ permanent;
	}
}
