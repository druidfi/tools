PHONY :=
PROJECT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
.DEFAULT_GOAL := help

# Include utils.mk
include $(PROJECT_DIR)/make/utils.mk

PHONY += release
release: VERSION := $(shell date +%Y-%m-%d-%H-%M)
release: ## Make a new release of druidfi/tools
	$(call step,Make a new release $(VERSION))
	@sed -i '' "s/VERSION=.*/VERSION=$(VERSION)/g" update.sh
	@git add update.sh
	@git commit -m "Updated version to $(VERSION)"

.PHONY: $(PHONY)
