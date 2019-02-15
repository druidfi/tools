BUILD_TARGETS := vendor
CLEAN_FOLDERS += vendor
COMPOSER_VENDOR_BIN := vendor/bin
PHPUNIT_BIN := $(shell test -f vendor/bin/phpunit && echo vendor/bin/phpunit || echo no)

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

ifneq ($(PHPUNIT_BIN),no)
	TEST_TARGETS += test-phpunit

	PHONY += test-phpunit
	test-phpunit: ## Run PHPUnit tests
		$(call call_in_root,${PHPUNIT_BIN} -c phpunit.xml.dist --testsuite unit)
endif

define composer_on_docker
	$(call call_in_root,composer --ansi $(1))
endef

define composer_on_host
	@composer --ansi $(1)
endef
