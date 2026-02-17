BINARY_NAME = ical-guy
PREFIX = /usr/local

BUILD_DIR = .build
RELEASE_BIN = $(BUILD_DIR)/release/$(BINARY_NAME)

.PHONY: build release test clean install uninstall universal lint lint-check lint-fix format format-check format-fix deps help

build: ## Build debug binary
	swift build

release: ## Build release binary
	swift build -c release

universal: ## Build universal (arm64 + x86_64) release binary
	swift build -c release --arch arm64 --arch x86_64

check: lint-check format-check ## Run lint/format checks

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

lint: lint-fix ## Alias for lint-fix
lint-check: ## Check SwiftLint (no changes)
	swiftlint
lint-fix: ## Run SwiftLint with auto-fix
	swiftlint --fix && swiftlint

format: format-fix ## Alias for format-fix
format-check: ## Check swift-format (no changes)
	swift-format lint --recursive Sources Tests
format-fix: ## Run swift-format with auto-fix
	swift-format format --in-place --recursive Sources Tests

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
