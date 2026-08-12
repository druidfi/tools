BUILD_TARGETS += composer-install

PHONY += composer-info
composer-info: ## Composer info
	$(call step,Do Composer info...\n)
	$(call composer,info)

PHONY += composer-update
composer-update: ## Update Composer packages
	$(call step,Do Composer update...\n)
	$(call composer,update)

PHONY += composer-install
composer-install: ## Install Composer packages
	$(call step,Do Composer install...\n)
	$(call composer,install)

PHONY += composer-outdated
composer-outdated: ## Show outdated Composer packages
	$(call step,Show outdated Composer packages...\n)
	$(call composer,outdated --direct)

define composer
	$(call docker_compose_exec,composer --ansi$(if $(filter $(COMPOSER_JSON_PATH),.),, --working-dir=$(COMPOSER_JSON_PATH)) $(1))
endef
