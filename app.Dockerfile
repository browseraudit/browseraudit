FROM debian:bullseye-slim

ARG GOLANG_VERSION=1.21.6

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        nano \
        make \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL "https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

RUN curl -sSfL https://raw.githubusercontent.com/cosmtrek/air/master/install.sh | \
        sh -s -- -b /usr/local/bin


WORKDIR /app

# 1. copy only go.mod/go.sum to leverage Docker layer cache
COPY go.mod go.sum ./
RUN go mod download

# 2. copy the rest of the source
COPY . .

