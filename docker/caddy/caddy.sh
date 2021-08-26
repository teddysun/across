#!/bin/sh
#
# This is a Shell script for caddy based alpine with Docker image
# 
# Copyright (C) 2019 - 2021 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/caddyserver/caddy
# https://github.com/caddyserver/forwardproxy

PLATFORM=$1
if [ -z "$PLATFORM" ]; then
    ARCH="amd64"
else
    case "$PLATFORM" in
        linux/386)
            ARCH="386"
            ;;
        linux/amd64)
            ARCH="amd64"
            ;;
        linux/arm/v6)
            ARCH="arm6"
            ;;
        linux/arm/v7)
            ARCH="arm7"
            ;;
        linux/arm64|linux/arm64/v8)
            ARCH="arm64"
            ;;
        linux/ppc64le)
            ARCH="ppc64le"
            ;;
        linux/s390x)
            ARCH="s390x"
            ;;
        *)
            ARCH=""
            ;;
    esac
fi
[ -z "${ARCH}" ] && echo "Error: Not supported OS Architecture" && exit 1
# Download binary file
CADDY_FILE="caddy_linux_${ARCH}"

echo "Downloading binary file: ${CADDY_FILE}"
wget -O /usr/bin/caddy https://dl.lamp.sh/files/${CADDY_FILE} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to download binary file: ${CADDY_FILE}" && exit 1
fi
echo "Download binary file: ${CADDY_FILE} completed"

chmod +x /usr/bin/caddy
