CLI_SERVICE := drupal
CLI_SHELL := bash
CLI_USER := drupal

PHONY += amazeeio-env
amazeeio-env: ## Print Amazee.io env variables
	$(call call_in_webroot, printenv | grep AMAZEE)

PHONY += versions
versions: ## Show software versions inside the Drupal container
	$(call colorecho, "\nSoftware versions on ${RUN_ON}:\n")
	$(call call_in_root,php -v && echo " ")
	$(call composer_on_${RUN_ON}, --version && echo " ")
	$(call drush_on_${RUN_ON},--version)
	$(call call_in_root,echo 'NPM version: '|tr '\n' ' ' && npm --version)
	$(call call_in_root,echo 'Yarn version: '|tr '\n' ' ' && yarn --version)
