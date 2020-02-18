#!/bin/sh
#
# This is a Shell script for build multi-architectures v2ray binary file
# 
# Supported architectures: amd64, arm32v6, arm32v7, arm64v8, i386, ppc64le, s390x
# 
# Copyright (C) 2020 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/v2ray/v2ray-core.git

cur_dir="$(pwd)"

COMMANDS=( git go )
for CMD in "${COMMANDS[@]}"; do
    if [ ! "$(command -v "${CMD}")" ]; then
        echo "${CMD} is not installed, please install it and try again" && exit 1
    fi
done

cd ${cur_dir}
git clone https://github.com/v2ray/v2ray-core.git
cd v2ray-core || exit 2

# Fixed issues below:
# ../go/pkg/mod/golang.org/x/crypto@v0.0.0-20190308221718-c2843e01d9a2/poly1305/sum_s390x.go:29:5: undefined: cpu.S390X
# ../go/pkg/mod/golang.org/x/crypto@v0.0.0-20190308221718-c2843e01d9a2/sha3/sha3_s390x.go:235:5: undefined: cpu.S390X

sed -i "s@golang.org/x/crypto.*@golang.org/x/crypto master@" go.mod
go mod tidy

LDFLAGS="-s -w"
ARCHS=( 386 amd64 arm arm64 ppc64le s390x )
ARMS=( 6 7 )

for ARCH in ${ARCHS[@]}; do
    if [ "${ARCH}" = "arm" ]; then
        for V in ${ARMS[@]}; do
            echo "Building v2ray_linux_${ARCH}${V} and v2ctl_linux_${ARCH}${V}"
            env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GOARM=${V} go build -v -ldflags "${LDFLAGS}" -o ${cur_dir}/v2ray_linux_${ARCH}${V} ./main
            env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GOARM=${V} go build -v -ldflags "${LDFLAGS}" -o ${cur_dir}/v2ctl_linux_${ARCH}${V} ./infra/control/main
        done
    else
        echo "Building v2ray_linux_${ARCH} and v2ctl_linux_${ARCH}"
        env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} go build -v -ldflags "${LDFLAGS}" -o ${cur_dir}/v2ray_linux_${ARCH} ./main
        env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} go build -v -ldflags "${LDFLAGS}" -o ${cur_dir}/v2ctl_linux_${ARCH} ./infra/control/main
    fi
done

chmod +x ${cur_dir}/v2ray_linux_* ${cur_dir}/v2ctl_linux_*
# clean up
cd ${cur_dir} && rm -fr v2ray-core
