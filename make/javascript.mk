BUILD_TARGETS += node_modules

node_modules: package.json ## Install NPM packages
	$(call colorecho, "\n-Do npm install (${RUN_ON})...\n")
	$(call npm_on_${RUN_ON},install --engine-strict true)

define npm_on_docker
	$(call call_in_root,npm $(1))
endef

define npm_on_host
	@npm $(1)
endef
