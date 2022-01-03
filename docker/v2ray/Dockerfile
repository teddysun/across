# Dockerfile for v2ray based alpine
# Copyright (C) 2019 - 2021 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/v2fly/v2ray-core
# https://github.com/v2fly/geoip
# https://github.com/v2fly/domain-list-community

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

WORKDIR /root
COPY v2ray.sh /root/v2ray.sh
COPY config.json /etc/v2ray/config.json
RUN set -ex \
	&& apk add --no-cache tzdata ca-certificates \
	&& mkdir -p /var/log/v2ray /usr/share/v2ray \
	&& chmod +x /root/v2ray.sh \
	&& /root/v2ray.sh \
	&& rm -fv /root/v2ray.sh \
	&& wget -O /usr/share/v2ray/geosite.dat https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat \
	&& wget -O /usr/share/v2ray/geoip-only-cn-private.dat https://github.com/v2fly/geoip/releases/latest/download/geoip-only-cn-private.dat \
	&& wget -O /usr/share/v2ray/geoip.dat https://github.com/v2fly/geoip/releases/latest/download/geoip.dat

VOLUME /etc/v2ray
ENV TZ=Asia/Shanghai
CMD [ "/usr/bin/v2ray", "run", "-config", "/etc/v2ray/config.json" ]
