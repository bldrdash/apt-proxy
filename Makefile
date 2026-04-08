# Makefile for apt-proxy

BINARY_NAME ?= apt-proxy
GO ?= go
PKGS ?= ./...
OTHER_FLAGS ?= -trimpath
BUILD_TARGET ?= ./cmd/apt-proxy
GORELEASER ?= goreleaser

# Version metadata injected at build time
VERSION := $(shell git describe --tags --exact-match 2>/dev/null || echo "dev")
COMMIT  := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DIRTY   := $(shell git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null || echo "true")
ifeq ($(DIRTY),)
DIRTY   := false
endif

# Build flags with version information
GO_LDFLAGS := -w -s \
	-X "github.com/soulteary/apt-proxy/internal/config.Version=$(VERSION)" \
	-X "github.com/soulteary/apt-proxy/internal/config.Commit=$(COMMIT)" \
	-X "github.com/soulteary/apt-proxy/internal/config.Dirty=$(DIRTY)"

 
.PHONY: all build test fmt vet lint clean install run docker-build goreleaser tag-bump

all: build

build:
	CGO_ENABLED=0 $(GO) build -ldflags '$(GO_LDFLAGS)' $(OTHER_FLAGS) -o $(BINARY_NAME) $(BUILD_TARGET)

test:
	$(GO) test $(PKGS)

vet:
	$(GO) vet $(PKGS)

run:
	$(GO) run $(BUILD_TARGET)

tag-bump:
	@CURRENT_BRANCH=$$(git rev-parse --abbrev-ref HEAD 2>/dev/null); \
	if [ "$$CURRENT_BRANCH" != "main" ]; then \
		echo "Error: bump-tag can only be run on the main branch. Currently on: $$CURRENT_BRANCH"; \
		exit 1; \
	fi
	@LATEST=$$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0"); \
	NEXT=$$(echo $$LATEST | awk -F. '{print $$1"."$$2"."$$3+1}'); \
	echo "Bumping $$LATEST -> $$NEXT"; \
	git tag -a $$NEXT -m "Release $$NEXT"