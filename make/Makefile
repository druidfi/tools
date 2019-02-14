.DEFAULT_GOAL := help

BUILD_TARGETS :=
CLEAN_FOLDERS := node_modules
CLI_SERVICE := cli
CLI_SHELL := sh
CLI_USER := root
COMPOSER_BIN := $(shell which composer || echo no)
DOCKER_COMPOSE_BIN := $(shell which docker-compose || echo no)
ifeq ($(shell test -f docker-compose.yml && echo yes),yes)
    DOCKER_COMPOSE_YML_EXISTS := yes
else
		DOCKER_COMPOSE_YML_EXISTS := no
endif
DRUIDFI_TOOLS_MAKE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ENV := dev
PHP_BIN := $(shell which php)

# If docker-compose.yml exists
ifeq ($(DOCKER_COMPOSE_YML_EXISTS),yes)
	# If docker-compose does not exist (e.g. inside Docker container)
	ifeq ($(DOCKER_COMPOSE_BIN),no)
		RUN_ON := host
		RUN_ON_DOCKER := no
	else
		RUN_ON := docker
		RUN_ON_DOCKER := yes
	endif
else
	RUN_ON := host
	RUN_ON_DOCKER := no
endif

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

PHONY += debug
debug: ## Show debug information
	$(call colorecho, "Debug starts:")
	$(call colorecho, "COMPOSER_BIN: ${COMPOSER_BIN}")
	$(call colorecho, "DOCKER_COMPOSE_BIN: ${DOCKER_COMPOSE_BIN}")
	$(call colorecho, "DOCKER_COMPOSE_YML_EXISTS: ${DOCKER_COMPOSE_YML_EXISTS}")
	$(call colorecho, "ENV: ${ENV}")
	$(call colorecho, "ENV var DRUPAL_IMAGE: ${DRUPAL_IMAGE}")
	$(call colorecho, "PHP_BIN: ${PHP_BIN}")
	$(call colorecho, "RUN_ON: ${RUN_ON}")
	$(call colorecho, "RUN_ON_DOCKER: ${RUN_ON_DOCKER}")
	$(call colorecho, "CLEAN_FOLDERS: ${CLEAN_FOLDERS}")
	$(call colorecho, "CLI_SERVICE: ${CLI_SERVICE}")
	$(call colorecho, "CLI_USER: ${CLI_USER}")
	$(call colorecho, "CLI_SHELL: ${CLI_SHELL}")
ifeq ($(RUN_ON_DOCKER),yes)
	$(call colorecho, "We should run on Docker and not on host")
else
	$(call colorecho, "We should run on host and not on Docker")
endif
	$(call colorecho, "End of debug.")

PHONY += help
help: ## List all make commands
	$(call colorecho, "\nAvailable make commands:")
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort

node_modules: package.json
	$(call colorecho, "\n- Install node modules inside Docker container...\n")
	$(call call_in_root, npm install --engine-strict true)

PHONY += self-update
self-update: ## Self-update all the tools from druidfi/tools
	$(call colorecho, "BETA: self update with Composer")
	$(call composer_on_${RUN_ON},update druidfi/tools --no-plugins)

define build_theme
    @echo "Implement project specific build_theme function to make/{somefile}.mk file (DEV=${DEV})"
endef

define colorecho
    @tput -T xterm setaf 3
    @echo $1
    @tput -T xterm sgr0
endef

# Include druidfi/tools make files
include $(DRUIDFI_TOOLS_MAKE_DIR)include.mk
