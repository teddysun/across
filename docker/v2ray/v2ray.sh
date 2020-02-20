#!/bin/sh
#
# This is a Shell script for v2ray based alpine with Docker image
# 
# Copyright (C) 2019 - 2020 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/v2ray/v2ray-core.git

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
V2RAY_FILE="v2ray_linux_${ARCH}"
V2CTL_FILE="v2ctl_linux_${ARCH}"

echo "Downloading binary file: ${V2RAY_FILE}"
wget -O /usr/bin/v2ray https://dl.lamp.sh/files/${V2RAY_FILE} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to download binary file: ${V2RAY_FILE}" && exit 1
fi
echo "Download binary file: ${V2RAY_FILE} completed"

echo "Downloading binary file: ${V2CTL_FILE}"
wget -O /usr/bin/v2ctl https://dl.lamp.sh/files/${V2CTL_FILE} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to download binary file: ${V2CTL_FILE}" && exit 1
fi
echo "Download binary file: ${V2CTL_FILE} completed"
chmod +x /usr/bin/v2ray
chmod +x /usr/bin/v2ctl
