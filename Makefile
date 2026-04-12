.PHONY: build clean lint check help

# Default target
.DEFAULT_GOAL := help

# Variables
PROJECT := foqos.xcodeproj
SCHEME := foqos
CONFIGURATION := Debug
DESTINATION := generic/platform=iOS Simulator

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the project
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration $(CONFIGURATION) -destination '$(DESTINATION)' build

clean: ## Clean build artifacts
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean

lint: ## Check Swift formatting
	swift-format lint --recursive .

lint-fix: ## Fix Swift formatting issues
	swift-format format --recursive --in-place .

check: ## Run lint and build
	$(MAKE) lint
	$(MAKE) build
