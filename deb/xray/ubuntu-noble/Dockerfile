# syntax=docker/dockerfile:1

ARG GO_IMAGE
ARG DISTRO=ubuntu
ARG SUITE=noble
ARG VERSION_ID=24.04
ARG BUILD_IMAGE=${DISTRO}:${SUITE}

FROM ${GO_IMAGE} AS golang

FROM ${BUILD_IMAGE}

# Remove diverted man binary to prevent man-pages being replaced with "minimized" message. See docker/for-linux#639
RUN if  [ "$(dpkg-divert --truename /usr/bin/man)" = "/usr/bin/man.REAL" ]; then \
        rm -f /usr/bin/man; \
        dpkg-divert --quiet --remove --rename /usr/bin/man; \
    fi

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl devscripts equivs git

ENV GOPROXY=https://proxy.golang.org|direct
ENV GO111MODULE=off
ENV GOPATH /go
ENV GOTOOLCHAIN=local
ENV PATH $PATH:/usr/local/go/bin:$GOPATH/bin

ARG COMMON_FILES
COPY --link ${COMMON_FILES} /root/build-deb/debian
RUN apt-get update \
 && mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i /root/build-deb/debian/control

COPY --link sources/ /sources
ARG DISTRO
ARG SUITE
ARG VERSION_ID
ENV DISTRO=${DISTRO}
ENV SUITE=${SUITE}
ENV VERSION_ID=${VERSION_ID}

COPY --link --from=golang /usr/local/go /usr/local/go

WORKDIR /root/build-deb
COPY build-deb /root/build-deb/build-deb

ENTRYPOINT ["/root/build-deb/build-deb"]
