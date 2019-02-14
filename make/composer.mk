CLEAN_FOLDERS += vendor

PHONY += composer-update
composer-update: ## Update Composer packages
	$(call colorecho, "\nDo Composer update (${RUN_ON})...\n")
	$(call composer_on_${RUN_ON},update)

PHONY += fix
fix: ## Fix code style
	$(call ${RUN_ON},fix)

vendor: composer.json composer.lock ## Install Composer packages
	$(call colorecho, "\nDo Composer install (${RUN_ON})...\n")
	$(call composer_on_${RUN_ON},install)

PHONY += test
test: ## Run tests
	$(call composer_on_${RUN_ON},test)

define build
	$(call colorecho, "\nBuild ${ENV} codebase (${RUN_ON})...\n")
	$(call composer_on_${RUN_ON},install)
endef

define composer_on_docker
	$(call call_in_root,composer --ansi $(1))
endef

define composer_on_host
	@composer --ansi $(1)
endef
