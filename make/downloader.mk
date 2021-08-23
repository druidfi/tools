DOWNLOADER_IMAGE := druidfi/backupper-downloader
DOWNLOADER_IMAGE_EXISTS := $(shell docker inspect --type=image $(DOWNLOADER_IMAGE) >/dev/null 2>&1 && echo "yes" || echo "no")

PHONY += download-dump
download-dump: ## Download a database dump
ifeq ($(DUMP_SQL_EXISTS),no)
ifeq ($(DOWNLOADER_IMAGE_EXISTS),yes)
	$(call step,Download & extract database dump...)
	@docker run -it --rm -v $(PWD)/tmp:/app/downloads $(DOWNLOADER_IMAGE) download $(DOWNLOADER_PROJECT)
	@gunzip tmp/$(DUMP_SQL_FILENAME).gz && mv tmp/$(DUMP_SQL_FILENAME) $(DUMP_SQL_FILENAME) && rm -rf tmp
else
	$(call warn,Downloader image "$(DOWNLOADER_IMAGE)" was not found!\n\n   Get it from https://github.com/druidfi/backupper/releases/tag/latest)
	@exit 1
endif
endif
