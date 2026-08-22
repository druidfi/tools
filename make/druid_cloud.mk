SSH_USER ?= deployment
SSH_TESTING ?= testing.host
SSH_STAGING ?= staging.host
SSH_PRODUCTION ?= production.host

PHONY += --get-current-build
--get-current-build:
	$(call step,Get current Build...)
	$(eval BUILD := $(shell ssh $(SSH) "docker inspect -f '{{ index .Config.Labels \"gha.build\" }}' $(PROJECT)-$(INSTANCE)"))
	$(call sub_step,Current Build is $(BUILD)\n)

PHONY += --deploy
--deploy: --get-current-build
	$(call step,Validate Docker Compose config...\n)
	$(AT)BUILD=$(BUILD) op run --env-file="./.env.$(INSTANCE)" -- docker compose config
	$(call step,Deploy Build $(BUILD) on $(INSTANCE)...\n)
	$(AT)BUILD=$(BUILD) op run --env-file="./.env.$(INSTANCE)" -- docker compose up --wait --remove-orphans
	$(call step,Run post-deploy tasks...\n)
	$(AT)ssh $(SSH) docker exec $(PROJECT)-$(INSTANCE) drush --ansi deploy

PHONY += deploy-testing
deploy-testing: INSTANCE := test
deploy-testing: SSH := $(SSH_USER)@$(SSH_TESTING)
deploy-testing: --deploy ## Deploy to Testing

PHONY += deploy-staging
deploy-staging: INSTANCE := stg
deploy-staging: SSH := $(SSH_USER)@$(SSH_STAGING)
deploy-staging: --deploy ## Deploy to Staging

PHONY += deploy-production
deploy-production: INSTANCE := prod
deploy-production: SSH := $(SSH_USER)@$(SSH_PRODUCTION)
deploy-production: --deploy ## Deploy to Production

PHONY += --shell-remote
--shell-remote:
	$(AT)ssh $(SSH)

PHONY += shell-testing
shell-testing: SSH := $(SSH_USER)@$(SSH_TESTING)
shell-testing: --shell-remote ## Shell into Testing

PHONY += shell-staging
shell-staging: SSH := $(SSH_USER)@$(SSH_STAGING)
shell-staging: --shell-remote ## Shell into Staging

PHONY += shell-production
shell-production: SSH := $(SSH_USER)@$(SSH_PRODUCTION)
shell-production: --shell-remote ## Shell into Production
