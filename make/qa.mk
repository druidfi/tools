TEST_TARGETS += test-phpunit
FIX_TARGETS :=
LINT_PHP_TARGETS :=
CS_INSTALLED := $(shell test -f $(COMPOSER_JSON_PATH)/vendor/bin/phpcs && echo yes || echo no)
CS_CONF_EXISTS := $(shell test -f phpcs.xml.dist && echo yes || echo no)
TESTSUITES ?= unit,kernel,functional
CYPRESS_DIR = cypress-toolkit
CYPRESS_SETUP = $(shell test -d $(CYPRESS_DIR) && echo yes || echo no)
NVM_SH := $(HOME)/.nvm/nvm.sh
NODE_VERSION ?= 20

PHONY += fix
fix: ## Fix code style
	$(call step,Fix code...)
	$(call sub_step,Following targets will be run: $(FIX_TARGETS))
	@$(MAKE) $(FIX_TARGETS)

PHONY += lint
lint: lint-php lint-js ## Check code style

PHONY += lint-js
lint-js: DOCKER_NODE_IMG ?= node:$(NODE_VERSION)-alpine
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
	$(call sub_step,Following targets will be run: $(LINT_PHP_TARGETS))
	@$(MAKE) $(LINT_PHP_TARGETS)
	$(call test_result,lint-php,"[OK]")

PHONY += test
test: ## Run tests
	$(call group_step,Run test targets:${NO_COLOR} $(TEST_TARGETS)\n)
	@$(MAKE) $(TEST_TARGETS)
	$(call step,Tests completed.)

PHONY += test-phpunit
test-phpunit: ## Run PHPUnit tests
	$(call step,Run PHPUnit tests...)
ifeq ($(CI),true)
	vendor/bin/phpunit -c phpunit.xml.dist --testsuite $(TESTSUITES)
else
	$(call docker_compose_exec,${DOCKER_PROJECT_ROOT}/vendor/bin/phpunit -c $(DOCKER_PROJECT_ROOT)/phpunit.xml.dist \
		--testsuite $(TESTSUITES))
endif
	$(call test_result,test-phpunit,"[OK]")

PHONY += test-phpunit-locally
test-phpunit-locally:
	@SIMPLETEST_BASE_URL=https://$(DRUPAL_HOSTNAME) SIMPLETEST_DB=mysql://$(DB_URL) \
    		vendor/bin/phpunit -c $(CURDIR)/phpunit.xml.dist --testsuite $(TESTSUITES)

define test_result
	@echo "\n${YELLOW}${1}:${NO_COLOR} ${GREEN}${2}${NO_COLOR}"
endef

ifeq ($(CS_INSTALLED)-$(CS_CONF_EXISTS),yes-yes)
define cs
$(call docker_compose_exec,vendor/bin/$(1))
endef
else ifeq ($(CS_INSTALLED)-$(CS_CONF_EXISTS),yes-no)
define cs
$(call docker_compose_exec,vendor/bin/$(1) --standard=$(CS_STANDARDS) --extensions=$(CS_EXTS) --ignore=node_modules $(2))
endef
else
define cs
$(call warn,CodeSniffer is not installed!)
endef
endif

PHONY += cypress-init
cypress-init: ## Init cypress
	$(call step,Adding cypress-toolkit to the project...\n)
	@git clone --recursive git@github.com:druidfi/cypress-toolkit.git

PHONY += cypress-install
cypress-install: ## Install cypress
	$(call step,Install npm packages\n)
	@cd $(CYPRESS_DIR) && \
	chmod u+x $(NVM_SH) && \
	. $(NVM_SH) && nvm use $(NODE_VERSION) && \
	node -v && pwd && \
	npm i --silence

PHONY += cypress-update
cypress-update: ## Update cypress
	$(call step,Update cypress-toolkit from github...\n)
	@git submodule update --init --remote --recursive
	$(call step,Update npm packages\n)
	@cd $(CYPRESS_DIR) && \
	chmod u+x $(NVM_SH) && \
	. $(NVM_SH) && nvm use $(NODE_VERSION) && \
	node -v && \
	npm update

PHONY += cypress-open
cypress-open: ## Update cypress
	$(call step,Open Cypress UI...\n)
	@cd $(CYPRESS_DIR) && \
	. $(NVM_SH) && nvm use $(NODE_VERSION) && \
	node -v && \
	npx cypress open

PHONY += cypress-run-tests
cypress-run-tests: ## Run cypress tests
ifeq ($(CYPRESS_SETUP), yes)
	@cd $(CYPRESS_DIR) && \
	. $(NVM_SH) && nvm use $(NODE_VERSION) && \
	node -v \
	ifeq ($(CYPRESS_LOCAL_CONFIG),yes)
		@cd ../CYPRESS_LOCAL_DIR && \
		cypress run --config-file ../tests/cypress/cypress.config.js
	else
		npx cypress run
	endif
endif

PHONY += cypress-remove
cypress-remove: ## Run cypress tests
ifeq ($(CYPRESS_SETUP), yes)
	@rm -fR $(CYPRESS_DIR)
endif
