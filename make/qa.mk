TEST_TARGETS += lint-php lint-js test-phpunit

PHONY += fix
fix: ## Fix code style
	$(call step,Fix code with PHP Code Beautifier and Fixer...)
	@docker run --rm -it $(subst $(space),'',$(LINT_PATHS_PHP)) druidfi/drupal-qa:8 bash -c "phpcbf ."

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
	@docker run --rm -it $(subst $(space),'',$(LINT_PATHS_PHP)) druidfi/drupal-qa:8 bash -c "phpcs -n ."
	$(call test_result,lint-php,"[OK]")

PHONY += test
test: ## Run tests
	$(call step,Run tests:\n- Following test targets will be run: $(TEST_TARGETS))
	@$(MAKE) $(TEST_TARGETS)
	$(call step,Tests completed.)

PHONY += test-phpunit
test-phpunit: TESTSUITES := unit,kernel,functional
test-phpunit: ## Run PHPUnit tests
	$(call step,Run PHPUnit tests...)
ifeq ($(CI),true)
	@docker run --rm -it --network=host \
		-e SIMPLETEST_BASE_URL=http://127.0.0.1:8080 -e SIMPLETEST_DB=mysql://root@127.0.0.1/drupal \
		-v "$(CURDIR)":/app:cached $(DRUPAL_IMAGE) \
		bash -c "vendor/bin/phpunit -c /app/phpunit.xml.dist --testsuite $(TESTSUITES)"
else
	$(call docker_run_cmd,cd ${DOCKER_PROJECT_ROOT} && vendor/bin/phpunit -c /app/phpunit.xml.dist --testsuite $(TESTSUITES))
endif
	$(call test_result,test-phpunit,"[OK]")

define test_result
	@echo "\n${YELLOW}${1}:${NO_COLOR} ${GREEN}${2}${NO_COLOR}"
endef
