.DEFAULT_GOAL := help
SHELL := /bin/bash

.PHONY: help
help: ## Show all available commands
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-13s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST);

.PHONY: bump
bump: format  # You must install uv https://docs.astral.sh/uv/getting-started/installation/
	@echo "You must have committed your changes before running this"
	@uv run bump-my-version bump patch;
	@echo "Upgraded version to $(shell bump-my-version show current_version)"
	@git add .bumpversion.toml
	@git commit -m "Upgraded version to $(shell bump-my-version show current_version)"

.PHONY: format
format: # You must install terraform https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
	@echo "Enforcing formatting"
	@terraform fmt -recursive;
	@uv run ruff format .;
	@uv run ruff check --fix-only --unsafe-fixes .;

.PHONY: quality
quality:
	@uv run ruff check .;
	@terraform fmt -check -recursive -diff;
	@uv run mypy .;
