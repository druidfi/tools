CLI_SERVICE := app
CLI_SHELL := sh
# Note: specification says this file would be compose.yaml
DOCKER_COMPOSE_YML_PATH ?= compose.yaml
DOCKER_COMPOSE_YML_EXISTS := $(shell test -f $(DOCKER_COMPOSE_YML_PATH) && echo yes || echo no)
DOCKER_PROJECT_ROOT ?= /app

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
	$(call docker_compose,exec $(CLI_SERVICE) $(CLI_SHELL))

PHONY += ssh-check
ssh-check: ## Check SSH keys on CLI container
	$(call docker_compose_exec,ssh-add -L)

define docker_compose_exec
	$(call docker_compose,exec$(if $(CLI_USER), -u $(CLI_USER),) $(CLI_SERVICE) $(CLI_SHELL) -c "$(1)")
	$(if $(2),@echo "$(2)",)
endef

define docker_compose
	$(AT)docker compose$(if $(filter $(DOCKER_COMPOSE_YML_PATH),$(DOCKER_COMPOSE_YML_PATH)),, -f $(DOCKER_COMPOSE_YML_PATH)) $(1)
endef
