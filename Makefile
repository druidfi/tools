PHONY :=
PROJECT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
.DEFAULT_GOAL := help

# Include utils.mk
include $(PROJECT_DIR)/make/utils.mk

PHONY += release
release: VERSION := $(shell date +%Y-%m-%d-%H-%M)
release: test ## Make a new release of druidfi/tools
	$(call step,Make a new release $(VERSION))
	@sed -i '' "s/VERSION=.*/VERSION=$(VERSION)/g" update.sh
	@git add update.sh
	@git commit -m "Updated version to $(VERSION)"
	@git push

PHONY += test
test: ## Run tests
	$(call step,Run tests)
	@tests/tests.sh

PHONY += test-linux
test-linux: ## Run tests on Linux
	@docker build . -t druidfi/tools-tester
	@docker run --rm -it --name druidfi-tools-linux -v $(PWD)/:/tools druidfi/tools-tester tests/tests.sh

.PHONY: $(PHONY)
