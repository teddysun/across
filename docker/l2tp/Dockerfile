# Dockerfile for L2TP/IPSec VPN Server
# Copyright (C) 2018 Teddysun <i@teddysun.com>

FROM debian:stretch
LABEL maintainer="Teddysun <i@teddysun.com>"

RUN set -ex \
	&& printf "deb http://deb.debian.org/debian sid main" > /etc/apt/sources.list.d/sid.list \
	&& apt-get update \
	&& apt-get -t sid install -y --no-install-recommends libreswan xl2tpd \
	&& apt-get install -y --no-install-recommends wget iproute2 openssl ca-certificates kmod net-tools iptables \
	&& apt-get -y autoremove \
	&& apt-get -y clean \
	&& rm -rf /var/lib/apt/lists/*

COPY ./ipsec /etc/init.d/ipsec
COPY ./l2tp.sh /usr/bin/l2tp
COPY ./l2tpctl.sh /usr/bin/l2tpctl
RUN chmod 755 /etc/init.d/ipsec /usr/bin/l2tp /usr/bin/l2tpctl

VOLUME /lib/modules

EXPOSE 500/udp 4500/udp

CMD [ "l2tp" ]
