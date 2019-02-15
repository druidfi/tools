.DEFAULT_GOAL := help

BUILD_TARGETS :=
CLEAN_FOLDERS := node_modules
CLI_SERVICE := cli
CLI_SHELL := sh
CLI_USER := root
COMPOSER_BIN := $(shell which composer || echo no)
COMPOSER_JSON_EXISTS := $(shell test -f composer.json && echo yes || echo no)
DOCKER_COMPOSE_BIN := $(shell which docker-compose || echo no)
DOCKER_COMPOSE_YML_EXISTS := $(shell test -f docker-compose.yml && echo yes || echo no)
DRUIDFI_TOOLS_MAKE_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ENV := dev
PHP_BIN := $(shell which php)

# Colors
NO_COLOR=\033[0m
GREEN=\033[0;32m
RED=\033[0;31m
YELLOW=\033[0;33m

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

PHONY += debug
debug: ## Show debug information
	@echo "${GREEN}Debug starts:${NO_COLOR}"
	$(call dbg,COMPOSER_BIN,${COMPOSER_BIN})
	$(call dbg,COMPOSER_JSON_EXISTS,${COMPOSER_JSON_EXISTS})
	$(call dbg,DOCKER_COMPOSE_BIN,${DOCKER_COMPOSE_BIN})
	$(call dbg,DOCKER_COMPOSE_YML_EXISTS,${DOCKER_COMPOSE_YML_EXISTS})
	$(call dbg,ENV,${ENV})
	$(call dbg,ENV var DRUPAL_IMAGE,${DRUPAL_IMAGE})
	$(call dbg,PHP_BIN,${PHP_BIN})
	$(call dbg,RUN_ON,${RUN_ON})
	$(call dbg,RUN_ON_DOCKER,${RUN_ON_DOCKER})
	$(call dbg,CLEAN_FOLDERS,${CLEAN_FOLDERS})
	$(call dbg,CLI_SERVICE,${CLI_SERVICE})
	$(call dbg,CLI_USER,${CLI_USER})
	$(call dbg,CLI_SHELL,${CLI_SHELL})
ifeq ($(RUN_ON_DOCKER),yes)
	$(call colorecho, "We should run on Docker and not on host")
else
	$(call colorecho, "We should run on host and not on Docker")
endif
	@echo "${GREEN}End of debug.${NO_COLOR}"

node_modules: package.json
	$(call colorecho, "\n- Install node modules inside Docker container...\n")
	$(call call_in_root, npm install --engine-strict true)

define colorecho
	@tput -T xterm setaf 3
	@echo $1
	@tput -T xterm sgr0
endef

define dbg
	@echo "${GREEN}${1}:${NO_COLOR} ${2}"
endef

# Include druidfi/tools make files
include $(DRUIDFI_TOOLS_MAKE_DIR)include.mk
