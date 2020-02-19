# Dockerfile for Brook based alpine
# Copyright (C) 2019 - 2020 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/txthinking/brook

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

WORKDIR /root
COPY brook.sh /root/brook.sh
RUN set -ex \
	&& apk add --no-cache tzdata \
	&& chmod +x /root/brook.sh \
	&& /root/brook.sh \
	&& rm -fv /root/brook.sh

ENV TZ=Asia/Shanghai
ENV ARGS="server -l :9000 -p password0"

CMD brook $ARGS
