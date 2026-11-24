CLI_SERVICE := app
CLI_SHELL := sh
# Note: specification says this file would be compose.yaml
DOCKER_COMPOSE_YML_PATH ?= compose.yaml
DOCKER_COMPOSE_YML_EXISTS := $(shell test -f $(DOCKER_COMPOSE_YML_PATH) && echo yes || echo no)
DOCKER_PROJECT_ROOT ?= /app
# Pass host Composer credentials (GitHub token, private repos) into the CLI container.
# Order: existing COMPOSER_AUTH env > Composer auth.json > GitHub CLI token (gh auth token).
# auth.json is looked up like Composer does: COMPOSER_AUTH_FILE if set, else $COMPOSER_HOME,
# else ${XDG_CONFIG_HOME:-~/.config}/composer (Linux default), then ~/.composer (macOS default).
# Passed by name (-e COMPOSER_AUTH) so the token never appears in process arguments.
COMPOSER_AUTH_CANDIDATES = $(if $(COMPOSER_AUTH_FILE),"$(COMPOSER_AUTH_FILE)",$(if $(COMPOSER_HOME),"$(COMPOSER_HOME)/auth.json",\
	"$${XDG_CONFIG_HOME:-$$HOME/.config}/composer/auth.json" "$$HOME/.composer/auth.json"))
# Simply expanded (:=) so the $(shell) runs once at parse time, not once per target
# (an exported recursive variable is re-expanded each time make builds a child environment).
ifndef COMPOSER_AUTH
COMPOSER_AUTH := $(shell \
	for f in $(COMPOSER_AUTH_CANDIDATES); do [ -f "$$f" ] && { cat "$$f"; exit 0; }; done; \
	if command -v gh >/dev/null 2>&1 && t=$$(gh auth token 2>/dev/null) && [ -n "$$t" ]; then \
		printf '{"github-oauth":{"github.com":"%s"}}' "$$t"; fi)
endif
export COMPOSER_AUTH

PHONY += config
config: ## Show docker-compose config
	$(call step,Show Docker Compose config...\n)
	$(call docker_compose,config)

PHONY += pull
pull: ## Pull docker images
	$(call step,Pull the latest docker images...\n)
	$(call docker_compose,pull)

PHONY += down
down: ## Tear down the environment
	$(call step,Tear down the environment...\n)
	$(call docker_compose,down -v --remove-orphans --rmi local)

PHONY += ps
ps: ## List containers
	$(call step,List container(s)...\n)
	$(call docker_compose,ps)

PHONY += stop
stop: ## Stop the environment
	$(call step,Stop the container(s)...\n)
	$(call docker_compose,stop)

PHONY += up
up: ## Launch the environment
	$(call step,Start up the container(s)...\n)
	$(call docker_compose,up --wait --remove-orphans)

PHONY += shell
shell: ## Login to CLI container
	$(call docker_compose,exec -e COMPOSER_AUTH $(CLI_SERVICE) $(CLI_SHELL))

PHONY += ssh-check
ssh-check: ## Check SSH keys on CLI container
	$(call docker_compose_exec,ssh-add -L)

define docker_compose_exec
	$(call docker_compose,exec -e COMPOSER_AUTH$(if $(CLI_USER), -u $(CLI_USER),) $(CLI_SERVICE) $(CLI_SHELL) -c "$(1)")
	$(if $(2),@echo "$(2)",)
endef

define docker_compose
	$(AT)docker compose$(if $(filter $(DOCKER_COMPOSE_YML_PATH),$(DOCKER_COMPOSE_YML_PATH)),, -f $(DOCKER_COMPOSE_YML_PATH)) $(1)
endef
