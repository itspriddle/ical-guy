BINARY_NAME = ical-guy
PREFIX = /usr/local

BUILD_DIR = .build
RELEASE_BIN = $(BUILD_DIR)/release/$(BINARY_NAME)

.PHONY: build release test clean install uninstall universal lint format deps help

build: ## Build debug binary
	swift build

release: ## Build release binary
	swift build -c release

universal: ## Build universal (arm64 + x86_64) release binary
	swift build -c release --arch arm64 --arch x86_64

test: ## Run tests
	swift test

clean: ## Remove build artifacts
	swift package clean

install: release ## Install to PREFIX (default: /usr/local)
	install -d $(PREFIX)/bin
	install $(RELEASE_BIN) $(PREFIX)/bin/$(BINARY_NAME)

uninstall: ## Remove installed binary
	rm -f $(PREFIX)/bin/$(BINARY_NAME)

deps: ## Install dependencies via Homebrew
	brew bundle

lint: ## Run SwiftLint
	swiftlint

format: ## Run swift-format
	swift-format format --in-place --recursive Sources Tests

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
