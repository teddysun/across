# Dockerfile for KMS Server
# Copyright (C) 2018 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/Wind4/vlmcsd

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

ENV KMS_RELEASE https://github.com/Wind4/vlmcsd/archive/master.zip

RUN runDeps="\
		g++ \
		gcc \
		wget \
		make \
		unzip \
	"; \
	set -ex \
	&& apk add --no-cache --virtual .build-deps ${runDeps} \
	&& cd /tmp \
	&& wget -O vlmcsd.zip ${KMS_RELEASE} \
	&& unzip vlmcsd.zip \
	&& cd vlmcsd-master \
	&& make \
	&& cp -p bin/vlmcsd /usr/bin/ \
	&& chmod 755 /usr/bin/vlmcsd \
	&& rm -rf /tmp/vlmcsd.zip /tmp/vlmcsd-master \
	&& apk del .build-deps

EXPOSE 1688

CMD [ "vlmcsd", "-D" ]
