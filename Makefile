.PHONY: build clean lint lint-fix mac-build mac-clean mac-dev mac-install mac-logs mac-release mac-reset mac-test test test-all check help

# Default target
.DEFAULT_GOAL := help

# Variables
PROJECT := foqos.xcodeproj
SCHEME := foqos
CONFIGURATION := Debug
DESTINATION := generic/platform=iOS Simulator
TEST_DESTINATION ?= platform=iOS Simulator,name=iPhone 17,OS=latest
UNIT_TEST_TARGET ?= foqosTests
MAC_SCHEME := Foqos Mac
MAC_TEST_SCHEME := FoqosMacTests
MAC_CONFIGURATION ?= Debug
MAC_DESTINATION := platform=macOS
MAC_DERIVED_DATA ?= $(TMPDIR)foqos-mac-derived-data
MAC_APP := $(MAC_DERIVED_DATA)/Build/Products/$(MAC_CONFIGURATION)/Foqos for Mac.app
MAC_INSTALL_PATH ?= /Applications/Foqos for Mac.app
MAC_LEGACY_INSTALL_PATH := /Applications/Foqos Mac.app
MAC_BUNDLE_IDENTIFIER := dev.ambitionsoftware.foqos.mac
BUILD_NUMBER ?= $(shell git rev-list --count HEAD)
NOTARY_PROFILE ?= foqos-notary
SPARKLE_KEY_ACCOUNT ?= ambitionsoftware
GITHUB_REPOSITORY ?= awaseem/foqos
RELEASE_NOTES_FILE ?=
LSREGISTER := /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the project
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(DESTINATION)' build

mac-build: ## Build the signed Mac app and system extension for local development
	xcodebuild -project $(PROJECT) -scheme '$(MAC_SCHEME)' -configuration $(MAC_CONFIGURATION) -destination '$(MAC_DESTINATION)' -derivedDataPath '$(MAC_DERIVED_DATA)' build

mac-clean: ## Clean local Mac build artifacts
	xcodebuild -project $(PROJECT) -scheme '$(MAC_SCHEME)' -configuration $(MAC_CONFIGURATION) -derivedDataPath '$(MAC_DERIVED_DATA)' clean

mac-install: mac-build
	@pkill -x 'Foqos for Mac' >/dev/null 2>&1 || true
	@pkill -x 'Foqos Mac' >/dev/null 2>&1 || true
	rm -rf '$(MAC_INSTALL_PATH)'
	rm -rf '$(MAC_LEGACY_INSTALL_PATH)'
	ditto '$(MAC_APP)' '$(MAC_INSTALL_PATH)'
	@mdfind 'kMDItemCFBundleIdentifier == "$(MAC_BUNDLE_IDENTIFIER)"' | while IFS= read -r app_path; do \
		if [ "$$app_path" != '$(MAC_INSTALL_PATH)' ] && [ -d "$$app_path" ]; then \
			'$(LSREGISTER)' -u "$$app_path" >/dev/null 2>&1 || true; \
		fi; \
	done
	@'$(LSREGISTER)' -u '$(MAC_APP)' >/dev/null 2>&1 || true
	'$(LSREGISTER)' -f '$(MAC_INSTALL_PATH)'

mac-dev: mac-install ## Install the local Mac build in Applications and launch it
	open '$(MAC_INSTALL_PATH)'

mac-reset: MAC_CONFIGURATION := Debug
mac-reset: mac-install ## Remove the local Foqos filter configuration and system extension
	'$(MAC_INSTALL_PATH)/Contents/MacOS/Foqos for Mac' --reset-network-extension
	@if /usr/bin/systemextensionsctl list | grep -Fq '$(MAC_BUNDLE_IDENTIFIER).filter'; then \
		echo 'macOS still has Foqos extension records. Restart this Mac before testing a fresh install.'; \
	fi

mac-logs: ## Stream structured Mac filter observations and verdicts
	log stream --style compact --level info --predicate 'subsystem == "dev.ambitionsoftware.foqos.mac.filter"'

mac-test: ## Run Mac TCP/TLS filter unit tests
	xcodebuild -project $(PROJECT) -scheme '$(MAC_TEST_SCHEME)' -configuration Debug -destination '$(MAC_DESTINATION)' CODE_SIGNING_ALLOWED=NO test

mac-release: ## Build, notarize, package, sign, and publish a Mac release (VERSION=x.y.z)
	@VERSION='$(VERSION)' \
	BUILD_NUMBER='$(BUILD_NUMBER)' \
	NOTARY_PROFILE='$(NOTARY_PROFILE)' \
	SPARKLE_KEY_ACCOUNT='$(SPARKLE_KEY_ACCOUNT)' \
	GITHUB_REPOSITORY='$(GITHUB_REPOSITORY)' \
	RELEASE_NOTES_FILE='$(RELEASE_NOTES_FILE)' \
	./scripts/release-mac.sh

clean: ## Clean build artifacts
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean

lint: ## Check Swift formatting
	swift-format lint --recursive .

lint-fix: ## Fix Swift formatting issues
	swift-format format --recursive --in-place .

test: ## Run unit tests
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(TEST_DESTINATION)' test -only-testing:$(UNIT_TEST_TARGET)

test-all: ## Run all tests, including UI tests
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(TEST_DESTINATION)' test

check: ## Run lint and build
	$(MAKE) lint
	$(MAKE) build
