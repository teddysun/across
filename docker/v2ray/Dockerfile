# Dockerfile for v2ray based alpine
# Copyright (C) 2019 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/v2ray/v2ray-core

FROM golang:alpine AS builder
RUN set -ex \
	&& apk add --no-cache git build-base \
	&& mkdir -p /go/src/github.com/v2ray \
	&& cd /go/src/github.com/v2ray \
	&& git clone https://github.com/v2ray/v2ray-core.git \
	&& cd v2ray-core \
	&& go get -d \
	&& cd main \
	&& go build -o /go/bin/v2ray \
	&& cd ../infra/control/main \
	&& go build -o /go/bin/v2ctl

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

RUN set -ex \
	&& apk add --no-cache tzdata ca-certificates \
	&& mkdir -p /etc/v2ray \
	&& mkdir -p /var/log/v2ray

COPY --from=builder /go/bin/v2ray /usr/bin
COPY --from=builder /go/bin/v2ctl /usr/bin
COPY config.json /etc/v2ray/config.json
VOLUME /etc/v2ray

ENV TZ=Asia/Shanghai

CMD [ "v2ray", "-config", "/etc/v2ray/config.json" ]
