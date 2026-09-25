.DEFAULT_GOAL := help

SWIFT := swift
BINARY_NAME := ical-guy
PREFIX := /usr/local
BUILD_DIR := .build
RELEASE_BIN := $(BUILD_DIR)/release/$(BINARY_NAME)

##@ Development

.PHONY: build
build: ## Build debug binary
	$(SWIFT) build

.PHONY: build-release
build-release: ## Build release binary
	$(SWIFT) build -c release

.PHONY: build-universal
build-universal: ## Build universal (arm64 + x86_64) release binary
	$(SWIFT) build -c release --arch arm64 --arch x86_64

.PHONY: test
test: ## Run all tests
	$(SWIFT) test

##@ Code Quality

.PHONY: check
check: lint-check format-check ## Run lint and format checks

.PHONY: lint
lint: ## Lint with SwiftLint (auto-fix)
	swiftlint --fix && swiftlint

.PHONY: lint-check
lint-check: ## Lint with SwiftLint (dry run)
	swiftlint

.PHONY: format
format: ## Format with swift-format
	swift-format format --in-place --recursive Sources Tests

.PHONY: format-check
format-check: ## Check formatting with swift-format (dry run)
	swift-format lint --recursive Sources Tests

##@ Installation

.PHONY: install
install: build-release ## Install to PREFIX (default: /usr/local)
	install -d $(PREFIX)/bin
	install $(RELEASE_BIN) $(PREFIX)/bin/$(BINARY_NAME)

.PHONY: uninstall
uninstall: ## Remove installed binary
	rm -f $(PREFIX)/bin/$(BINARY_NAME)

##@ Maintenance

.PHONY: clean
clean: ## Remove build artifacts
	$(SWIFT) package clean

.PHONY: deps
deps: ## Install dependencies via Homebrew
	brew bundle

.PHONY: resolve
resolve: ## Resolve package dependencies
	$(SWIFT) package resolve

.PHONY: update
update: ## Update package dependencies
	$(SWIFT) package update

##@ Info

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
