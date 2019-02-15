PHONY += artifact
artifact: vendor ## Make tar.gz package from the current build
	$(call colorecho, "\nCreate artifact:\n")
	@tar -hczf artifact.tar.gz --files-from=conf/artifact/include --exclude-from=conf/artifact/exclude

PHONY += build
build: $(BUILD_TARGETS) ## Build codebase(s)
	$(call colorecho, "\nStart build for env: $(ENV)")
	$(call colorecho, "- Following targets will be run: $(BUILD_TARGETS)")
	@$(MAKE) $(BUILD_TARGETS)
	$(call colorecho, "\nBuild completed.")

PHONY += clean
clean: ## Clean folders
	$(call colorecho, "\nClean folders: ${CLEAN_FOLDERS}")
	@rm -rf ${CLEAN_FOLDERS}

PHONY += help
help: ## List all make commands
	$(call colorecho, "\nAvailable make commands:")
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort

PHONY += self-update
self-update: ## Self-update all the tools from druidfi/tools
	$(call colorecho, "BETA: self update with Composer")
	$(call composer_on_${RUN_ON},update druidfi/tools --no-plugins)
