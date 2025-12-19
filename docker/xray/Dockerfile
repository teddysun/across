# Dockerfile for xray based alpine
# Copyright (C) 2019 - 2025 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/XTLS/Xray-core
# https://github.com/v2fly/v2ray-core
# https://github.com/Loyalsoldier/v2ray-rules-dat

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

WORKDIR /root
COPY xray.sh /root/xray.sh
COPY config.json /etc/xray/config.json
RUN set -ex \
	&& apk add --no-cache bash tzdata ca-certificates openssl \
	&& mkdir -p /var/log/xray /usr/share/xray \
	&& chmod +x /root/xray.sh \
	&& /root/xray.sh \
	&& rm -fv /root/xray.sh \
	&& wget -O /usr/share/xray/geosite.dat https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geosite.dat \
	&& wget -O /usr/share/xray/geoip.dat https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/geoip.dat

VOLUME /etc/xray
ENV TZ=Asia/Shanghai
CMD [ "/usr/bin/xray", "-config", "/etc/xray/config.json" ]
