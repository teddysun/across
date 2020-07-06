# Dockerfile for KMS Server
# Copyright (C) 2018 - 2020 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/Wind4/vlmcsd

FROM alpine:latest AS builder
WORKDIR /root
RUN apk add --no-cache git make build-base && \
    git clone --branch master --single-branch https://github.com/Wind4/vlmcsd.git && \
    cd vlmcsd/ && \
    make

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

COPY --from=builder /root/vlmcsd/bin/vlmcsd /usr/bin/vlmcsd
EXPOSE 1688
CMD [ "/usr/bin/vlmcsd", "-D", "-e" ]
