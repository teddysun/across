#!/bin/sh
#
# This is a Shell script for build multi-architectures brook binary file
# 
# Supported architectures: amd64, arm32v6, arm32v7, arm64v8, i386, ppc64le, s390x
# 
# Copyright (C) 2020 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/txthinking/brook

cur_dir="$(pwd)"

COMMANDS=( git go )
for CMD in "${COMMANDS[@]}"; do
    if [ ! "$(command -v "${CMD}")" ]; then
        echo "${CMD} is not installed, please install it and try again" && exit 1
    fi
done

cd ${cur_dir}
git clone https://github.com/txthinking/brook.git
cd brook/cli/brook || exit 2
go get -d -v

LDFLAGS="-s -w"
ARCHS=( 386 amd64 arm arm64 ppc64le s390x )
ARMS=( 6 7 )

for ARCH in ${ARCHS[@]}; do
    if [ "${ARCH}" = "arm" ]; then
        for V in ${ARMS[@]}; do
            echo "Building brook_linux_${ARCH}${V}"
            env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GOARM=${V} go build -v -ldflags "${LDFLAGS}" -o ${cur_dir}/brook_linux_${ARCH}${V}
        done
    else
        echo "Building brook_linux_${ARCH}"
        env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} go build -v -ldflags "${LDFLAGS}" -o ${cur_dir}/brook_linux_${ARCH}
    fi
done

chmod +x ${cur_dir}/brook_linux_*
# clean up
cd ${cur_dir} && rm -fr brook
