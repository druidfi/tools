# Colors
NO_COLOR=\033[0m
CYAN=\033[36m
GREEN=\033[0;32m
RED=\033[0;31m
YELLOW=\033[0;33m

PHONY += help
help: ## List all make commands
	$(call step,Available make commands:)
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "${CYAN}%-30s${NO_COLOR} %s\n", $$1, $$2}' | sort

define dbg
	@printf "${GREEN}${1}:${NO_COLOR} ${2}\n"
endef

define step
	@printf "\n⚡ ${YELLOW}${1}${NO_COLOR}\n\n"
endef

define sub_step
	@printf "\n   ${YELLOW}${1}${NO_COLOR}\n\n"
endef

define warn
	@printf "\n⚠️  ${1}\n\n"
endef
