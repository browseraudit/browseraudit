# Define NGINX version as a build argument
ARG NGINX_VERSION=1.18.0

# First stage: Build dynamic modules
FROM nginx:${NGINX_VERSION}-alpine AS builder

# Install dependencies and build tools
RUN apk add --no-cache \
    build-base \
    pcre-dev \
    zlib-dev \
    linux-headers \
    openssl-dev \
    geoip-dev \
    libxslt-dev \
    gd-dev \
    curl \
    git \
    libmaxminddb-dev

WORKDIR /usr/local/src

# Download Nginx source to match the running version
RUN curl -fL -o nginx.tar.gz http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -zxvf nginx.tar.gz && \
    mv nginx-${NGINX_VERSION} /usr/local/src/nginx && \
    rm nginx.tar.gz

# Clone third-party modules
RUN git clone https://github.com/arut/nginx-dav-ext-module.git && \
    git clone https://github.com/openresty/echo-nginx-module.git && \
    git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git && \
    git clone https://github.com/leev/ngx_http_geoip2_module.git

# Configure and compile dynamic modules
WORKDIR /usr/local/src/nginx
RUN ./configure \
    --with-compat \
    --add-dynamic-module=../nginx-dav-ext-module \
    --add-dynamic-module=../echo-nginx-module \
    --add-dynamic-module=../ngx_http_substitutions_filter_module \
    --add-dynamic-module=../ngx_http_geoip2_module \
    --with-stream=dynamic \
    --with-stream_geoip_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_xslt_module=dynamic \
    --with-http_ssl_module \
    --with-http_v2_module

RUN make modules && mkdir -p /etc/nginx/modules && \
    cp objs/ngx_*.so /etc/nginx/modules

# Second stage: Final image with compiled modules
FROM nginx:${NGINX_VERSION}-alpine

# Install runtime dependency for geoip2
RUN apk add --no-cache libmaxminddb

COPY --from=builder /etc/nginx/modules /etc/nginx/modules

RUN rm /etc/nginx/nginx.conf && \
    ln -s /srv/browseraudit/sysadmin/nginx/nginx.conf /etc/nginx/nginx.conf

RUN rm /etc/nginx/mime.types && \
    ln -s /srv/browseraudit/sysadmin/nginx/mime.types /etc/nginx/mime.types
