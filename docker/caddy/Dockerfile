# Dockerfile for caddy v1.0.5 based alpine
# Copyright (C) 2021 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/caddyserver/caddy
# https://github.com/caddyserver/forwardproxy

FROM alpine:3.14
LABEL maintainer="Teddysun <i@teddysun.com>"

WORKDIR /root
COPY caddy.sh /root/caddy.sh
RUN set -ex \
	&& mkdir -p /config/caddy /data/caddy /etc/caddy /usr/share/caddy \
	&& apk add --no-cache tzdata ca-certificates mailcap \
	&& chmod +x /root/caddy.sh \
	&& /root/caddy.sh \
	&& rm -fv /root/caddy.sh

# set up nsswitch.conf for Go's "netgo" implementation
# see: https://github.com/docker-library/golang/blob/1eb096131592bcbc90aa3b97471811c798a93573/1.14/alpine3.12/Dockerfile#L9
RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

COPY Caddyfile /etc/caddy/Caddyfile
COPY index.html /usr/share/caddy/index.html

# See https://caddyserver.com/docs/conventions#file-locations for details
ENV XDG_CONFIG_HOME /config
ENV XDG_DATA_HOME /data

VOLUME /etc/caddy
VOLUME /config
VOLUME /data

EXPOSE 80 443 2015

ENV TZ=Asia/Shanghai
CMD [ "/usr/bin/caddy", "-conf", "/etc/caddy/Caddyfile", "-agree" ]
