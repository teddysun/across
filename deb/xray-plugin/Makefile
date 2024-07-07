ARCH=$(shell uname -m)
VERSION?=1.8.15
GO_VERSION:=1.22.5
SHELL:=/bin/bash
GO_BASE_IMAGE=golang
GO_IMAGE?=$(GO_BASE_IMAGE):$(GO_VERSION)-bookworm
EPOCH?=
REPO?=https://github.com/teddysun/xray-plugin.git
REF?=v1.8.15
CHOWN:=docker run --rm -v $(CURDIR):/v -w /v alpine chown

ifdef BUILD_IMAGE
	BUILD_IMAGE_FLAG=--build-arg $(BUILD_IMAGE)
endif

COMMON_FILES=common
BUILD?=DOCKER_BUILDKIT=1 \
	docker build \
	$(BUILD_IMAGE_FLAG) \
	--build-arg GO_IMAGE=$(GO_IMAGE) \
	--build-arg COMMON_FILES=$(COMMON_FILES) \
	-t debbuild-$@/$(ARCH) \
	-f $@/Dockerfile \
	.

# Additional flags may be necessary at some point
RUN_FLAGS=
RUN?=docker run --rm -h buildbot \
	-e PLATFORM \
	-e EPOCH='$(EPOCH)' \
	-e DEB_VERSION=$(VERSION) \
	-e VERSION=$(VERSION) \
	-v $(CURDIR)/debbuild/$@:/build \
	$(RUN_FLAGS) \
	debbuild-$@/$(ARCH)

DEBIAN_VERSIONS ?= debian-buster debian-bullseye debian-bookworm
UBUNTU_VERSIONS ?= ubuntu-focal ubuntu-jammy ubuntu-noble
DISTROS := $(DEBIAN_VERSIONS) $(UBUNTU_VERSIONS)

# Taken from: https://www.cmcrossroads.com/article/printing-value-makefile-variable
print-%  : ; @echo $($*)

.PHONY: help
help: ## show make targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf " \033[36m%-20s\033[0m  %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: checkout-src
checkout-src: src/github.com/teddysun/xray-plugin
	./checkout.sh src/github.com/teddysun/xray-plugin "$(REF)"

src/github.com/teddysun/xray-plugin:
	git init $@
	git -C $@ remote add origin "$(REPO)"

.PHONY: checkout
checkout: checkout-src ## checkout source at the given reference(s)

.PHONY: clean
clean: ## remove build artifacts
	[ ! -d debbuild ] || $(CHOWN) -R $(shell id -u):$(shell id -g) debbuild
	$(RM) -r debbuild
	[ ! -d sources ] || $(CHOWN) -R $(shell id -u):$(shell id -g) sources
	$(RM) -r sources
	-docker builder prune -f --filter until=24h

.PHONY: deb
deb: ubuntu debian ## build all deb packages

.PHONY: ubuntu
ubuntu: $(UBUNTU_VERSIONS) ## build all ubuntu deb packages

.PHONY: debian
debian: $(DEBIAN_VERSIONS) ## build all debian deb packages

.PHONY: $(DISTROS)
$(DISTROS): sources
	@echo "== Building packages for $@ =="
	mkdir -p "debbuild/$@"
	$(BUILD)
	$(RUN)
	$(CHOWN) -R $(shell id -u):$(shell id -g) "debbuild/$@"

.PHONY: sources
sources: sources/xray-plugin.tgz

sources/xray-plugin.tgz:
	mkdir -p $(@D)
	docker run --rm -w /v \
		-v $(realpath $(CURDIR)/src/github.com/teddysun/xray-plugin):/xray-plugin \
		-v $(CURDIR)/$(@D):/v \
		alpine \
		tar -C / -c -z -f /v/xray-plugin.tgz --exclude .git xray-plugin

# See ARCHES in common.mk. Could not figure out how to match both distro and arch.
BUNDLES:=$(addsuffix .tar.gz,$(addprefix debbuild/bundles-%-,$(ARCHES)))

$(BUNDLES): %
	tar czf $@ --transform="s|^debbuild/\(.*\)|bundles/$(VERSION)/build-deb/\1|" debbuild/$*
