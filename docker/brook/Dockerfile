# Dockerfile for Brook based alpine
# Copyright (C) 2019 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/txthinking/brook

FROM golang:alpine as builder
RUN set -ex && apk add --update git \
	&& go get -u -v github.com/txthinking/brook/cli/brook

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

COPY --from=builder /go/bin/brook /usr/bin

ENV ARGS="server -l :9000 -p password0"

CMD brook $ARGS
