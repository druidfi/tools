BUILD_TARGETS := vendor
CLEAN_FOLDERS += vendor
COMPOSER_VENDOR_BIN := vendor/bin
PHPUNIT_BIN := ${COMPOSER_VENDOR_BIN}/phpunit
PHPUNIT_BIN_EXISTS := $(shell test -f ${PHPUNIT_BIN} && echo yes || echo no)
TEST_TARGETS += test-phpunit

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

PHONY += test-phpunit
test-phpunit: ## Run PHPUnit tests
	@echo "- ${YELLOW}test-phpunit:${NO_COLOR} Start running PHPUnit tests..."
ifeq (${PHPUNIT_BIN_EXISTS},yes)
	$(call call_in_root,${PHPUNIT_BIN} -c phpunit.xml.dist --testsuite unit)
else
	@echo "- ${YELLOW}${PHPUNIT_BIN} does not exist! ${RED}[ERROR]${NO_COLOR}"
endif

define composer_on_docker
	$(call call_in_root,composer --ansi $(1))
endef

define composer_on_host
	@composer --ansi $(1)
endef
