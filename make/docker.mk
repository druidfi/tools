DOCKER_COMPOSER_EXEC := docker-compose exec -T
DOCKER_WARNING_INSIDE := "\nYou are inside the Docker container!\n"

PHONY += down
down: ## Tear down the environment
ifeq ($(RUN_ON),host)
	$(call colorecho,$(DOCKER_WARNING_INSIDE))
else
	$(call colorecho, "\nTear down the environment")
	@docker-compose down -v --remove-orphans
endif

PHONY += stop
stop: ## Stop the environment
ifeq ($(RUN_ON),host)
	$(call colorecho,$(DOCKER_WARNING_INSIDE))
else
	$(call colorecho, "\nStop the environment")
	@docker-compose stop
endif

PHONY += up
up: ## Launch the environment
ifeq ($(RUN_ON),host)
	$(call colorecho,$(DOCKER_WARNING_INSIDE))
else
	$(call colorecho, "\nStart up the container(s)\n")
	@docker-compose up -d --remove-orphans
endif

PHONY += docker-test
docker-test: ## Run docker targets on Docker and host
	$(call colorecho, "\nTest call_in_webroot on $(RUN_ON)")
	$(call call_in_webroot,pwd)
	$(call colorecho, "\nTest call_in_webroot on $(RUN_ON)")
	$(call call_in_root,pwd)

PHONY += shell
shell: ## Login to CLI container
ifeq ($(RUN_ON),host)
	$(call colorecho,$(DOCKER_WARNING_INSIDE))
else
	@docker-compose exec --user ${CLI_USER} ${CLI_SERVICE} ${CLI_SHELL}
endif

ifeq ($(RUN_ON),host)
define call_in_webroot
		@. ~/.bash_envvars && cd $$AMAZEEIO_WEBROOT && $(1)
endef
else
define call_in_webroot
		@${DOCKER_COMPOSER_EXEC} -u ${CLI_USER} ${CLI_SERVICE} ${CLI_SHELL} -c ". ~/.bash_envvars && cd \"$$AMAZEEIO_WEBROOT\" && PATH=`pwd`/vendor/bin:\$$PATH && $(1)"
endef
endif

ifeq ($(RUN_ON),host)
define call_in_root
		@. ~/.bash_envvars && cd /var/www/drupal/public_html && $(1)
endef
else
define call_in_root
    @${DOCKER_COMPOSER_EXEC} -u ${CLI_USER} ${CLI_SERVICE} ${CLI_SHELL} -c ". ~/.bash_envvars && cd /var/www/drupal/public_html && PATH=`pwd`/vendor/bin:\$$PATH && $(1)"
endef
endif
