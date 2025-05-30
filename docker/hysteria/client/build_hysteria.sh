#!/bin/sh
#
# This is a Shell script for build multi-architectures hysteria binary file
# 
# Supported architectures: amd64, arm32v6, arm32v7, arm64v8, i386, ppc64le, s390x
# 
# Copyright (C) 2022 - 2023 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/apernet/hysteria

cur_dir="$(pwd)"

COMMANDS=( git go )
for CMD in "${COMMANDS[@]}"; do
    if [ ! "$(command -v "${CMD}")" ]; then
        echo "${CMD} is not installed, please install it and try again" && exit 1
    fi
done

cd ${cur_dir}
echo "git clone https://github.com/apernet/hysteria.git"
git clone https://github.com/apernet/hysteria.git
cd hysteria || exit 2

APP_SRC_CMD_PKG="github.com/apernet/hysteria/app/cmd"
VERSION="$(git describe)"
COMMIT="$(git rev-parse HEAD)"
TIMESTAMP="$(date "+%F")"

LDFLAGS="-s -w -X '${APP_SRC_CMD_PKG}.appVersion=${VERSION}' -X '${APP_SRC_CMD_PKG}.appCommit=${COMMIT}' -X '${APP_SRC_CMD_PKG}.appDate=${TIMESTAMP}' -X '${APP_SRC_CMD_PKG}.appType=release' -buildid="
ARCHS=( 386 amd64 arm arm64 ppc64le s390x )
ARMS=( 6 7 )

for ARCH in ${ARCHS[@]}; do
    if [ "${ARCH}" = "arm" ]; then
        for V in ${ARMS[@]}; do
            echo "Building hysteria_linux_${ARCH}${V}"
            env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GOARM=${V} go build -v -trimpath -ldflags "${LDFLAGS} -X '${APP_SRC_CMD_PKG}.appPlatform=linux' -X '${APP_SRC_CMD_PKG}.appArch=${ARCH}'" -o ${cur_dir}/hysteria_linux_${ARCH}${V} ./app || exit 1
        done
    else
        echo "Building hysteria_linux_${ARCH}"
        env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} go build -v -trimpath -ldflags "${LDFLAGS} -X '${APP_SRC_CMD_PKG}.appPlatform=linux' -X '${APP_SRC_CMD_PKG}.appArch=${ARCH}'" -o ${cur_dir}/hysteria_linux_${ARCH} ./app || exit 1
    fi
done

ARCHS=( 386 amd64 )
for ARCH in ${ARCHS[@]}; do
    echo "Building hysteria_windows_${ARCH}.exe"
    env CGO_ENABLED=0 GOOS=windows GOARCH=${ARCH} go build -v -trimpath -ldflags "${LDFLAGS} -X '${APP_SRC_CMD_PKG}.appPlatform=windows' -X '${APP_SRC_CMD_PKG}.appArch=${ARCH}'" -o ${cur_dir}/hysteria_windows_${ARCH}.exe ./app
done

chmod +x ${cur_dir}/hysteria_*
# clean up
cd ${cur_dir} && rm -fr hysteria
