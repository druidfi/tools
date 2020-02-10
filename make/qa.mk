TEST_TARGETS += lint-php lint-js test-phpunit

PHONY += fix
fix: ## Fix code style
	$(call step,Fix code with PHP Code Beautifier and Fixer...)
	@$(MAKE) phpcs CMD=phpcbf FLAGS='.'

PHONY += lint
lint: lint-php lint-js ## Check code style

PHONY += lint-js
lint-js: DOCKER_NODE_IMG ?= node:8.16.0-alpine
lint-js: WD := /app
lint-js: ## Check code style for JS files
	$(call step,Install linters...)
	@docker run --rm -v "$(CURDIR)":$(WD):cached -w $(WD) $(DOCKER_NODE_IMG) yarn --cwd $(WEBROOT)/core install
	$(call step,Check code style for JS files: $(DRUPAL_LINT_PATHS))
	@docker run --rm -v "$(CURDIR)":$(WD):cached -w $(WD) $(DOCKER_NODE_IMG) \
		$(WEBROOT)/core/node_modules/eslint/bin/eslint.js --color --ignore-pattern '**/vendor/*' \
		--c ./$(WEBROOT)/core/.eslintrc.json --global nav,moment,responsiveNav:true $(LINT_PATHS_JS)

PHONY += lint-php
lint-php: ## Check code style for PHP files
	$(call step,Check code style for PHP files...)
	@$(MAKE) phpcs CMD=phpcs FLAGS='-n .'
	$(call test_result,lint-php,"[OK]")

PHONY += test
test: ## Run tests
	$(call step,Run tests:\n- Following test targets will be run: $(TEST_TARGETS))
	@$(MAKE) $(TEST_TARGETS)
	$(call step,Tests completed.)

PHONY += phpcs
phpcs: IMG := druidfi/drupal-qa:8
phpcs: CMD ?= phpcs
phpcs: FLAGS ?= -n .
phpcs:
	@docker run --rm -it $(subst $(space),'',$(LINT_PATHS_PHP)) $(IMG) bash -c "${CMD} ${FLAGS}"

PHONY += test-phpunit
test-phpunit: IMG := druidfi/drupal-qa:8
test-phpunit: ## Run PHPUnit tests
	$(call step,Run PHPUnit tests...)
	@docker run --rm -it -v "$(CURDIR)":/app:cached $(IMG) bash -c "phpunit -c phpunit.xml.dist --testsuite unit"
	$(call test_result,test-phpunit,"[OK]")

define test_result
	@echo "\n${YELLOW}${1}:${NO_COLOR} ${GREEN}${2}${NO_COLOR}"
endef
