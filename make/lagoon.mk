CLI_SERVICE := cli
CLI_SHELL := bash
DB_SERVICE := mariadb

SSH_OPTS ?= -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no
LAGOON_SSH_HOST ?= ssh.lagoon.amazeeio.cloud
LAGOON_SSH_OPTS ?= $(SSH_OPTS) -p 32222 -t
LAGOON_PROD_BRANCH ?= main
LAGOON_TEST_BRANCH ?= dev

ifeq ($(MAKECMDGOALS),set-lagoon-secrets)
include .env.local.lagoon
endif

PHONY += lagoon-env
lagoon-env: ## Print Lagoon env variables
	$(call docker_compose_exec,printenv | grep LAGOON_)

PHONY += --shell-lagoon
--shell-lagoon:
	ssh $(LAGOON_SSH_OPTS) $(SSH)

PHONY += shell-prod
shell-prod: SSH := $(PROJECT)-$(LAGOON_PROD_BRANCH)@$(LAGOON_SSH_HOST)
shell-prod: --shell-lagoon ## Shell into Lagoon prod

PHONY += shell-test
shell-test: SSH := $(PROJECT)-$(LAGOON_TEST_BRANCH)@$(LAGOON_SSH_HOST)
shell-test: --shell-lagoon ## Shell into Lagoon test

PHONY += deploy-lagoon-%
deploy-lagoon-%: ## Deploy lagoon branch
	$(call step,Deploy Lagoon branch $*...\n)
	@lagoon -p $(LAGOON_PROJECT) deploy branch -b $*

PHONY += set-lagoon-secrets-%
set-lagoon-secrets-%: ## Set Lagoon secrets
		$(call step,Set Lagoon secrets on $*...\n)
		@$(foreach secret,$(LAGOON_SECRETS),$(call set_lagoon_secret,$(secret),$*))

PHONY += list-lagoon-vars-%
list-lagoon-vars-%: ## List variables from Lagoon
		$(call step,List variables from Lagoon on $*...\n)
		@lagoon -p $(LAGOON_PROJECT) list v --reveal -e $*

define set_lagoon_secret
printf "Setting secret on ${2}: %s = %s \n" "${1}" "${${1}}";
lagoon -p $(LAGOON_PROJECT) a v -N "${1}" -V "${${1}}" -S runtime -e ${2} --force || true;
endef
