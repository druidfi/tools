DUMP_SQL_FILENAME ?= dump.sql
DUMP_SQL_EXISTS := $(shell test -f $(DUMP_SQL_FILENAME) && echo yes || echo no)
CLEAN_EXCLUDE := .idea $(DUMP_SQL_FILENAME) .env.local
PROJECT ?= myproject

PHONY += build
build: ## Build codebase(s)
	$(call group_step,Build:${NO_COLOR} $(BUILD_TARGETS))
	@$(MAKE) $(BUILD_TARGETS)

PHONY += clean
clean: ## Cleanup
	$(call step,Cleanup loaded files...\n)
	$(AT)rm -rf vendor
	$(AT)git clean -fdx $(foreach item,$(CLEAN_EXCLUDE),-e $(item))

PHONY += self-update
self-update: ## Self-update makefiles from druidfi/tools
	$(call step,Update makefiles from druidfi/tools\n)
	$(AT)bash -c "$$(curl -fsSL $(UPDATE_SCRIPT_URL))"

PHONY += sync
sync: ## Sync data from other environments
	$(call group_step,Sync:$(NO_COLOR) $(SYNC_TARGETS))
	@$(MAKE) $(SYNC_TARGETS)

PHONY += gh-download-dump
gh-download-dump: GH_FLAGS += $(if $(GH_ARTIFACT),-n $(GH_ARTIFACT),-n latest-dump)
gh-download-dump: GH_FLAGS += $(if $(GH_REPO),-R $(GH_REPO),)
gh-download-dump: ## Download database dump from repository artifacts
	$(call step,Download database dump from repository artifacts\n)
ifeq ($(DUMP_SQL_EXISTS),no)
	$(call run,gh run download $(strip $(GH_FLAGS)),Downloaded $(DUMP_SQL_FILENAME),Failed)
else
	@echo "There is already $(DUMP_SQL_FILENAME)"
endif
