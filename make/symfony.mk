sf-about: ## Displays information about the current project
	$(call sf_console_on_${RUN_ON},about)

define sf_console_on_docker
	$(call docker_run_cmd,bin/console --ansi $(1))
endef

define sf_console_on_host
	@bin/console --ansi $(1)
endef
