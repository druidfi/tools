DOWNLOADER_IMAGE := druidfi/backupper-downloader
DOWNLOADER_IMAGE_EXISTS := $(shell docker inspect --type=image $(DOWNLOADER_IMAGE) >/dev/null 2>&1 && echo "yes" || echo "no")

PHONY += download-dump
download-dump: ## Download a database dump
ifeq ($(DUMP_SQL_EXISTS),no)
ifeq ($(DOWNLOADER_IMAGE_EXISTS),no)
	$(call warn,Downloader image "$(DOWNLOADER_IMAGE)" was not found!)
	@exit 1
else
ifndef DOWNLOADER_PROJECT
	$(call warn,DOWNLOADER_PROJECT not set!)
	@exit 1
else
	$(call step,Download SQL dump...)
	@docker run -it --rm -v $(PWD)/tmp:/app/downloads $(DOWNLOADER_IMAGE) download $(DOWNLOADER_PROJECT)
	@gunzip tmp/$(DUMP_SQL_FILENAME).gz && mv tmp/$(DUMP_SQL_FILENAME) $(DUMP_SQL_FILENAME) && rm -rf tmp
endif
endif
endif

PHONY += help
help: ## List all make commands
	$(call step,Available make commands:)
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort

# Colors
NO_COLOR=\033[0m
GREEN=\033[0;32m
RED=\033[0;31m
YELLOW=\033[0;33m

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
