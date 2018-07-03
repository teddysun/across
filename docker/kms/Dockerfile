# Dockerfile for KMS Server
# Copyright (C) 2018 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/Wind4/vlmcsd

FROM alpine:latest
MAINTAINER Teddysun <i@teddysun.com>

ENV KMS_RELEASE https://github.com/Wind4/vlmcsd/archive/master.zip

RUN apk add --no-cache --virtual .build-deps \
    g++ \
    gcc \
    wget \
    make \
    unzip \
    && cd /tmp \
    && wget -O vlmcsd.zip $KMS_RELEASE \
    && unzip vlmcsd.zip \
    && cd vlmcsd-master \
    && make \
    && cp -p bin/vlmcsd /usr/bin/ \
    && chmod 755 /usr/bin/vlmcsd \
    && rm -rf /tmp/vlmcsd.zip /tmp/vlmcsd-master \
    && apk del .build-deps

EXPOSE 1688

CMD [ "/usr/bin/vlmcsd", "-D" ]
