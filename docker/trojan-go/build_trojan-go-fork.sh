#!/bin/bash
#
# This is a Shell script for build multi-architectures trojan-go binary file
# 
# Supported architectures: amd64, arm32v6, arm32v7, arm64v8, i386, ppc64le, s390x
# 
# Copyright (C) 2020 - 2023 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/p4gefau1t/trojan-go
# https://github.com/Potterli20/trojan-go-fork

cur_dir="$(pwd)"

COMMANDS=( git go )
for CMD in "${COMMANDS[@]}"; do
    if [ ! "$(command -v "${CMD}")" ]; then
        echo "${CMD} is not installed, please install it and try again" && exit 1
    fi
done

cd ${cur_dir}
#version=$(wget --no-check-certificate -qO- https://api.github.com/repos/p4gefau1t/trojan-go/tags | grep 'name' | cut -d\" -f4 | head -1)
#echo "git clone -b ${version} https://github.com/p4gefau1t/trojan-go.git"
echo "git clone https://github.com/Potterli20/trojan-go-fork.git"
#git clone -b ${version} https://github.com/p4gefau1t/trojan-go.git
git clone https://github.com/Potterli20/trojan-go-fork.git
cd trojan-go-fork || exit 2

PACKAGE_NAME="github.com/Potterli20/trojan-go-fork"
VERSION="$(git describe --tags)"
# VERSION="v2023.11.15"
COMMIT="$(git rev-parse HEAD)"

VAR_SETTING="-X ${PACKAGE_NAME}/constant.Version=${VERSION} -X ${PACKAGE_NAME}/constant.Commit=${COMMIT}"

LDFLAGS="-s -w ${VAR_SETTING} -buildid="
ARCHS=( 386 amd64 arm arm64 ppc64le s390x )
ARMS=( 6 7 )

for ARCH in ${ARCHS[@]}; do
    if [ "${ARCH}" = "arm" ]; then
        for V in ${ARMS[@]}; do
            echo "Building trojan-go_linux_${ARCH}${V}"
            env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GOARM=${V} go build -v -tags "full" -ldflags "${LDFLAGS}" -o ${cur_dir}/trojan-go_linux_${ARCH}${V}
        done
    else
        echo "Building trojan-go_linux_${ARCH}"
        env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} go build -v -tags "full" -ldflags "${LDFLAGS}" -o ${cur_dir}/trojan-go_linux_${ARCH}
    fi
done

chmod +x ${cur_dir}/trojan-go_linux_*
# clean up
cd ${cur_dir} && rm -fr trojan-go-fork
