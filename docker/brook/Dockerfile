# Dockerfile for Brook based alpine
# Copyright (C) 2019 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/txthinking/brook

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

ENV ARGS=

RUN set -ex \
	&& BROOK_VER="$(wget --no-check-certificate -qO- https://api.github.com/repos/txthinking/brook/tags | grep 'name' | head -1 | cut -d\" -f4)" \
	&& BROOK_RELEASE="https://github.com/txthinking/brook/releases/download/${BROOK_VER}/brook" \
	&& wget -O /usr/bin/brook ${BROOK_RELEASE} && chmod +x /usr/bin/brook

CMD exec /usr/bin/brook $ARGS
